import Foundation
import OSLog

// MARK: - CityActivityService

typealias Models = CityActivityAPIModels

// MARK: - CityActivityService

actor CityActivityService: CityActivityProviding {
    static let shared = CityActivityService()
    private static let cacheVersion = "v6"
    private static let desiredActivityCount = 6
    /// The City tab shows the top six, but trip planning needs a deeper pool so
    /// longer itineraries can be filled without repeating places.
    private static let rankedActivityLimit = 18
    static let sourceCandidateCount = 18

    let session: URLSession
    let wikipediaSummaryService: WikipediaSummaryProviding
    let overpassClient: OverpassClient
    let wikivoyageParser = WikivoyageActivityGuideParser()
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "CityActivityService"
    )
    private let cacheLifetime: TimeInterval = 60 * 60 * 24 * 14
    /// A guide built without Overpass is refetched soon, so the full ranking
    /// replaces it once Overpass recovers.
    private let partialCacheLifetime: TimeInterval = 60 * 30
    /// How long Overpass may hold a guide once the other sources are in.
    private static let overpassGrace: Duration = .seconds(3)
    /// Longer than Overpass's own time budget, so a sole source is never cut short.
    private static let primarySourceWait: Duration = .seconds(20)

    private var memoryCache: [String: Models.CachedPayload] = [:]
    /// Network fetches already underway, so a prefetch and the screen that
    /// needs the result share one fetch instead of running the pipeline twice.
    private var inFlightFetches: [String: Task<[CityActivity], Never>] = [:]

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

    init(
        session: URLSession = .shared,
        wikipediaSummaryService: WikipediaSummaryProviding = WikipediaSummaryService.shared
    ) {
        self.session = session
        self.wikipediaSummaryService = wikipediaSummaryService
        self.overpassClient = OverpassClient(session: session)
    }

    func activities(for city: CityModel) async -> [CityActivity] {
        let key = Self.cacheKey(for: city)

        if let cached = self.memoryCache[key], self.isFresh(cached) {
            return cached.activities
        }

        let diskURL = self.diskCacheURL(for: city)

        if let cached = self.loadFromDisk(at: diskURL), self.isFresh(cached) {
            self.memoryCache[key] = cached
            return cached.activities
        }

        if let inFlightFetch = self.inFlightFetches[key] {
            return await inFlightFetch.value
        }

        let fetch = Task { await self.fetchAndCacheActivities(for: city, key: key, diskURL: diskURL) }
        self.inFlightFetches[key] = fetch
        let activities = await fetch.value
        self.inFlightFetches[key] = nil
        return activities
    }

    private func fetchAndCacheActivities(
        for city: CityModel,
        key: String,
        diskURL: URL
    ) async -> [CityActivity] {
        let (activities, isPartial) = await self.fetchActivities(for: city)
        guard !activities.isEmpty else {
            if let stale = self.loadFromDisk(at: diskURL) {
                self.memoryCache[key] = stale
                return stale.activities
            }

            return []
        }

        let payload = Models.CachedPayload(fetchedAt: .now, activities: activities, isPartial: isPartial)
        try? self.writeToDisk(payload, at: diskURL)
        self.memoryCache[key] = payload
        return activities
    }
}

// MARK: - Fetch Pipeline (Overpass + Wikivoyage + Apple Maps, then Wikipedia)

extension CityActivityService {
    private func fetchActivities(
        for city: CityModel
    ) async -> (activities: [CityActivity], isPartial: Bool) {
        // The sources are independent, so they load together and the slowest
        // one sets the pace instead of their sum.
        let overpassSearch = Task { await self.overpassActivities(for: city) }
        async let wikivoyageActivities = self.wikivoyageActivities(for: city)
        async let mapKitSearch = Self.multiQueryMapKitSearch(for: city)
        // The fallback is a few fast Wikipedia calls, so it starts alongside the
        // primary sources and is only used when they come up short.
        async let wikipediaFallback = self.wikipediaFallbackActivities(for: city)

        let wikivoyage = await wikivoyageActivities
        let mapKitResults = await mapKitSearch

        // Overpass is the slowest and least reliable source. Once the others
        // are in, it gets a short grace period, unless it's all there is.
        let overpassWait = wikivoyage.isEmpty && mapKitResults.isEmpty
            ? Self.primarySourceWait
            : Self.overpassGrace
        let overpass = await overpassSearch.value(within: overpassWait)

        var collectedActivities = (overpass ?? []) + wikivoyage

        if CityActivityRanking.topActivities(
            from: collectedActivities,
            for: city,
            limit: Self.desiredActivityCount
        ).count < Self.desiredActivityCount {
            collectedActivities += await wikipediaFallback
        }

        let mapKitActivities = Self.mapKitActivities(
            for: city,
            results: mapKitResults,
            existingActivities: collectedActivities
        )
        collectedActivities += mapKitActivities

        let demandSignals = await self.demandSignals(
            for: collectedActivities,
            mapKitResults: mapKitResults
        )

        let rankedActivities = CityActivityRanking.topActivities(
            from: collectedActivities,
            for: city,
            demandSignals: demandSignals,
            limit: Self.rankedActivityLimit
        )

        let activities = await self.enrichFallbackActivitiesIfNeeded(rankedActivities, for: city)
        return (activities, isPartial: overpass == nil)
    }

    private func overpassActivities(for city: CityModel) async -> [CityActivity] {
        do {
            let pois = try await self.overpassPOIs(
                latitude: city.coordinate.latitude,
                longitude: city.coordinate.longitude,
                cityName: city.name
            )

            guard !pois.isEmpty else {
                self.logger.info(
                    "No Overpass POIs for \(city.name, privacy: .public)"
                )
                return []
            }

            let topPOIs = Array(pois.prefix(12))
            let enriched = await self.enrichWithWikipedia(pois: topPOIs)
            let withImages = await self.resolveWikidataImages(for: enriched)
            return Array(withImages.prefix(Self.sourceCandidateCount))
        } catch {
            self.logger.error(
                "Overpass activity fetch failed for \(city.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return []
        }
    }

    private func wikipediaFallbackActivities(for city: CityModel) async -> [CityActivity] {
        do {
            return try await self.fallbackWikipediaActivities(for: city)
        } catch {
            self.logger.error(
                "Wikipedia activity fallback failed for \(city.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return []
        }
    }

    private func fallbackWikipediaActivities(for city: CityModel) async throws -> [CityActivity] {
        let geoResults = try await self.wikiGeoSearch(
            latitude: city.coordinate.latitude,
            longitude: city.coordinate.longitude
        )

        let candidates = Self.filterGeoResults(geoResults, cityName: city.name)
        guard !candidates.isEmpty else { return [] }

        let titles = candidates.prefix(20).map(\.title)
        let pages = try await self.wikiPageDetails(for: Array(titles))
        let ranked = Self.rankPages(pages)
        let activities = Array(ranked.prefix(Self.sourceCandidateCount)).map {
            Self.mapPageToActivity(page: $0)
        }

        return await self.resolveWikidataImages(for: activities)
    }
}

// MARK: - Networking

extension CityActivityService {
    func fetchData(from url: URL, timeout: TimeInterval = 15) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .useProtocolCachePolicy
        request.timeoutInterval = timeout
        request.setValue(
            "TourismBeats/1.0 (\(Bundle.main.bundleIdentifier ?? "city-activities"))",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await self.session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw Models.ServiceError.invalidResponse
        }

        guard 200 ..< 300 ~= http.statusCode else {
            throw Models.ServiceError.httpStatus(http.statusCode)
        }

        return data
    }
}

// MARK: - Disk Cache

extension CityActivityService {
    private func isFresh(_ payload: Models.CachedPayload) -> Bool {
        payload.isValid(
            lifetime: payload.isPartial == true ? self.partialCacheLifetime : self.cacheLifetime
        )
    }

    private func loadFromDisk(at url: URL) -> Models.CachedPayload? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? self.decoder.decode(Models.CachedPayload.self, from: data)
    }

    private func writeToDisk(_ payload: Models.CachedPayload, at url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try self.encoder.encode(payload)
        try data.write(to: url, options: [.atomic])
    }

    private func diskCacheURL(for city: CityModel) -> URL {
        URL.cachesDirectory
            .appending(path: "CityActivities", directoryHint: .isDirectory)
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
