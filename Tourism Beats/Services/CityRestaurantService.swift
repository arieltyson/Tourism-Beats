import Foundation
import OSLog

// MARK: - CityRestaurantService

typealias RestaurantModels = CityRestaurantAPIModels

// MARK: - CityRestaurantService

actor CityRestaurantService: CityRestaurantProviding {
    static let shared = CityRestaurantService()
    private static let cacheVersion = "v7"
    /// The City tab shows the top six, but trip planning needs enough distinct
    /// restaurants to suggest a different meal for each day of a longer trip.
    private static let rankedRestaurantLimit = 18

    let session: URLSession
    let overpassClient: OverpassClient
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "CityRestaurantService"
    )
    private let cacheLifetime: TimeInterval = 60 * 60 * 24 * 3
    /// A guide built without some enrichment is refetched soon, so the full
    /// ranking replaces it once the slow sources recover.
    private let partialCacheLifetime: TimeInterval = 60 * 30
    /// How long enrichment may hold a guide once Apple Maps has answered.
    private static let enrichmentGrace: Duration = .seconds(3)
    /// Longer than Overpass's own time budget, so a primary source is never cut short.
    private static let primarySourceWait: Duration = .seconds(20)

    private var memoryCache: [String: RestaurantModels.CachedPayload] = [:]
    /// Network fetches already underway, so a prefetch and the screen that
    /// needs the result share one fetch instead of running the pipeline twice.
    private var inFlightFetches: [String: Task<[CityRestaurant], Never>] = [:]

    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    init(session: URLSession = .shared) {
        self.session = session
        self.overpassClient = OverpassClient(session: session)
    }

    func restaurants(for city: CityModel) async -> [CityRestaurant] {
        let key = Self.cacheKey(for: city)

        if let cached = self.memoryCache[key], self.isFresh(cached) {
            return cached.restaurants
        }

        let diskURL = self.diskCacheURL(for: city)

        if let cached = self.loadFromDisk(at: diskURL), self.isFresh(cached) {
            self.memoryCache[key] = cached
            return cached.restaurants
        }

        if let inFlightFetch = self.inFlightFetches[key] {
            return await inFlightFetch.value
        }

        let fetch = Task { await self.fetchAndCacheRestaurants(for: city, key: key, diskURL: diskURL) }
        self.inFlightFetches[key] = fetch
        let restaurants = await fetch.value
        self.inFlightFetches[key] = nil
        return restaurants
    }

    private func fetchAndCacheRestaurants(
        for city: CityModel,
        key: String,
        diskURL: URL
    ) async -> [CityRestaurant] {
        do {
            let (restaurants, isPartial) = try await self.fetchRestaurants(for: city)
            let payload = RestaurantModels.CachedPayload(
                fetchedAt: .now,
                restaurants: restaurants,
                isPartial: isPartial
            )
            try? self.writeToDisk(payload, at: diskURL)
            self.memoryCache[key] = payload
            return restaurants
        } catch {
            self.logger.error(
                "Restaurant fetch failed for \(city.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )

            if let stale = self.loadFromDisk(at: diskURL) {
                self.memoryCache[key] = stale
                return stale.restaurants
            }

            return []
        }
    }
}

// MARK: - Fetch Pipeline

extension CityRestaurantService {
    private func fetchRestaurants(
        for city: CityModel
    ) async throws -> (restaurants: [CityRestaurant], isPartial: Bool) {
        // Every source starts at once. Apple Maps is the primary source and the
        // rest only enrich it, so once it answers they share a short grace
        // period instead of their full time budgets. Without Apple Maps,
        // Overpass becomes the primary source and is waited for in full.
        let overpassSearch = Task { await self.overpassCandidatesIfAvailable(for: city) }
        let awardSearch = Task { [session = self.session] in
            await CityRestaurantWikidataService.fetchAwards(for: city, session: session)
        }
        let guideSearch = Task { await CityRestaurantWikivoyageService.fetchEatListings(for: city) }
        let chainScan = Task { await self.detectChainsFromWiderScan(for: city) }

        let mapKitResults = await Self.multiQueryMapKitSearch(for: city)
        let wait = mapKitResults.isEmpty ? Self.primarySourceWait : Self.enrichmentGrace

        async let overpassResult = overpassSearch.value(within: wait)
        async let awardResult = awardSearch.value(within: wait)
        async let chainResult = chainScan.value(within: wait)
        async let guideResult = guideSearch.value(within: wait)
        let (overpass, awards, chains, guideListings) = await (overpassResult, awardResult, chainResult, guideResult)
        let isPartial = overpass == nil || awards == nil || chains == nil || guideListings == nil

        let overpassCandidates = overpass ?? []
        var candidates: [CityRestaurantCandidate]

        if !mapKitResults.isEmpty {
            candidates = Self.mergeResults(
                mapKit: mapKitResults,
                overpass: overpassCandidates,
                cityName: city.name
            )
        } else if !overpassCandidates.isEmpty {
            self.logger.info(
                "MapKit unavailable, falling back to Overpass for \(city.name, privacy: .public)"
            )
            candidates = overpassCandidates.map { Self.candidate(from: $0) }
        } else {
            throw RestaurantModels.ServiceError.invalidResponse
        }

        let wikidataMatches = awards ?? []
        if !wikidataMatches.isEmpty {
            candidates = CityRestaurantWikidataService.enrichCandidates(
                candidates,
                with: wikidataMatches
            )
        }

        candidates = CityRestaurantWikivoyageService.markRecommendations(
            in: candidates,
            from: guideListings ?? []
        )

        candidates = Self.tagDuplicateLocationCounts(candidates)

        let chainSignatures = chains ?? []
        if !chainSignatures.isEmpty {
            candidates = Self.applyChainSignatures(chainSignatures, to: candidates)
        }

        let restaurants = CityRestaurantRanking.topRestaurants(
            from: candidates,
            for: city,
            limit: Self.rankedRestaurantLimit
        )
        return (restaurants, isPartial)
    }

    private func overpassCandidatesIfAvailable(
        for city: CityModel
    ) async -> [RestaurantModels.OverpassRestaurant] {
        do {
            return try await self.fetchOverpassCandidates(for: city)
        } catch {
            self.logger.info(
                "Overpass enrichment unavailable: \(error.localizedDescription, privacy: .public)"
            )
            return []
        }
    }

    private func fetchOverpassCandidates(
        for city: CityModel
    ) async throws -> [RestaurantModels.OverpassRestaurant] {
        let searchRadii = [8_000, 14_000]
        var candidates: [RestaurantModels.OverpassRestaurant] = []

        for radius in searchRadii {
            candidates = try await self.overpassRestaurants(
                latitude: city.coordinate.latitude,
                longitude: city.coordinate.longitude,
                cityName: city.name,
                radius: radius
            )

            if candidates.count >= 18 {
                break
            }
        }

        return candidates
    }
}

// MARK: - Disk Cache

extension CityRestaurantService {
    private func isFresh(_ payload: RestaurantModels.CachedPayload) -> Bool {
        payload.isValid(
            lifetime: payload.isPartial == true ? self.partialCacheLifetime : self.cacheLifetime
        )
    }

    private func loadFromDisk(at url: URL) -> RestaurantModels.CachedPayload? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? self.decoder.decode(RestaurantModels.CachedPayload.self, from: data)
    }

    private func writeToDisk(
        _ payload: RestaurantModels.CachedPayload,
        at url: URL
    ) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try self.encoder.encode(payload)
        try data.write(to: url, options: [.atomic])
    }

    private func diskCacheURL(for city: CityModel) -> URL {
        URL.cachesDirectory
            .appending(path: "CityRestaurants", directoryHint: .isDirectory)
            .appending(path: "\(Self.cacheKey(for: city)).json", directoryHint: .notDirectory)
    }

    private static func cacheKey(for city: CityModel) -> String {
        let normalizedCityIdentifier = city.id
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .joined(separator: "_")

        return "\(Self.cacheVersion)_\(normalizedCityIdentifier)"
    }
}
