import Foundation
import OSLog

// MARK: - CityRestaurantService

typealias RestaurantModels = CityRestaurantAPIModels

// MARK: - CityRestaurantService

actor CityRestaurantService: CityRestaurantProviding {
    static let shared = CityRestaurantService()
    private static let cacheVersion = "v2"
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

        if let cached = self.memoryCache[key],
           cached.isValid(lifetime: self.cacheLifetime)
        {
            return cached.restaurants
        }

        let diskURL = self.diskCacheURL(for: city)

        if let cached = self.loadFromDisk(at: diskURL),
           cached.isValid(lifetime: self.cacheLifetime)
        {
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
            let restaurants = try await self.fetchRestaurants(for: city)
            let payload = RestaurantModels.CachedPayload(
                fetchedAt: .now,
                restaurants: restaurants
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
    private func fetchRestaurants(for city: CityModel) async throws -> [CityRestaurant] {
        // Every source is independent, so they load together and the slowest
        // one sets the pace instead of their sum.
        async let mapKitSearch = Self.multiQueryMapKitSearch(for: city)
        async let overpassSearch = self.overpassCandidatesIfAvailable(for: city)
        async let awardSearch = CityRestaurantWikidataService.fetchAwards(
            for: city,
            session: self.session
        )
        async let chainScan = self.detectChainsFromWiderScan(for: city)

        let mapKitResults = await mapKitSearch
        let overpassCandidates = await overpassSearch

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

        let wikidataMatches = await awardSearch
        if !wikidataMatches.isEmpty {
            candidates = CityRestaurantWikidataService.enrichCandidates(
                candidates,
                with: wikidataMatches
            )
        }

        candidates = Self.tagDuplicateLocationCounts(candidates)

        let chainSignatures = await chainScan
        if !chainSignatures.isEmpty {
            candidates = Self.applyChainSignatures(chainSignatures, to: candidates)
        }

        return CityRestaurantRanking.topRestaurants(
            from: candidates,
            for: city,
            limit: Self.rankedRestaurantLimit
        )
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
