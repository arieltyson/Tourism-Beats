import Foundation

// MARK: - OverpassClient

/// Runs Overpass QL queries against the public, volunteer-run Overpass network.
///
/// Public instances are regularly saturated: the main server can answer
/// "at capacity" within a second while mirrors stall until they time out.
/// Queries go to one instance at a time. A refusal moves straight on to the
/// next instance, and a slow instance is hedged by also asking the next one
/// after a short delay. The first successful response wins and every other
/// request is cancelled, so servers are never all queried at once.
///
/// Overpass only enriches the guides, so a query never holds them up for
/// longer than its time budget. When every instance fails, the client stops
/// asking for a cooldown period so later cities load without the wait.
struct OverpassClient: Sendable {
    typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    enum ClientError: Error, Equatable {
        case invalidQuery
        case httpStatus(Int)
        case invalidResponse
        case timeBudgetExceeded
        case coolingDown
    }

    static let publicEndpoints: [URL] = [
        URL(string: "https://overpass-api.de/api/interpreter"),
        URL(string: "https://maps.mail.ru/osm/tools/overpass/api/interpreter"),
        URL(string: "https://overpass.private.coffee/api/interpreter"),
        URL(string: "https://overpass.kumi.systems/api/interpreter")
    ]
    .compactMap(\.self)

    private let endpoints: [URL]
    private let hedgeDelay: Duration
    private let timeBudget: Duration
    private let requestTimeout: TimeInterval
    private let availability: OverpassAvailability
    private let transport: Transport

    init(session: URLSession = .shared) {
        self.init(
            endpoints: Self.publicEndpoints,
            hedgeDelay: .seconds(3),
            timeBudget: .seconds(12),
            availability: .shared,
            transport: { request in try await session.data(for: request) }
        )
    }

    init(
        endpoints: [URL],
        hedgeDelay: Duration,
        timeBudget: Duration,
        availability: OverpassAvailability,
        transport: @escaping Transport
    ) {
        self.endpoints = endpoints
        self.hedgeDelay = hedgeDelay
        self.timeBudget = timeBudget
        self.requestTimeout = timeBudget.timeInterval
        self.availability = availability
        self.transport = transport
    }

    /// Returns the raw response body of the first instance to answer `query`.
    func data(for query: String) async throws -> Data {
        guard await self.availability.isAvailable() else {
            throw ClientError.coolingDown
        }

        let result = try await self.firstResponse(for: query)

        switch result {
        case .success:
            await self.availability.recordSuccess()
        case .failure:
            await self.availability.recordOutage()
        }

        return try result.get()
    }

    // MARK: Private

    private func firstResponse(for query: String) async throws -> Result<Data, any Error> {
        let requests = try self.endpoints.map { try self.request(for: query, endpoint: $0) }

        return await withTaskGroup(of: Event.self) { group -> Result<Data, any Error> in
            var nextIndex = 0
            var inFlight = Set<Int>()
            var lastError: any Error = ClientError.invalidResponse

            func launchNext(into group: inout TaskGroup<Event>) {
                guard nextIndex < requests.count else { return }

                let index = nextIndex
                let request = requests[index]
                nextIndex += 1
                inFlight.insert(index)

                group.addTask {
                    do {
                        return try await .finished(index, .success(self.perform(request)))
                    } catch {
                        return .finished(index, .failure(error))
                    }
                }

                if nextIndex < requests.count {
                    let delay = self.hedgeDelay
                    group.addTask {
                        try? await Task.sleep(for: delay)
                        return .hedgeDue(index)
                    }
                }
            }

            let budget = self.timeBudget
            group.addTask {
                try? await Task.sleep(for: budget)
                return .budgetExhausted
            }

            launchNext(into: &group)

            while let event = await group.next() {
                switch event {
                case let .finished(_, .success(data)):
                    group.cancelAll()
                    return .success(data)

                case let .finished(index, .failure(error)):
                    inFlight.remove(index)
                    lastError = error
                    launchNext(into: &group)

                case let .hedgeDue(index) where inFlight.contains(index):
                    launchNext(into: &group)

                case .hedgeDue:
                    break

                case .budgetExhausted:
                    group.cancelAll()
                    return .failure(ClientError.timeBudgetExceeded)
                }

                if inFlight.isEmpty, nextIndex == requests.count {
                    group.cancelAll()
                    return .failure(lastError)
                }
            }

            return .failure(lastError)
        }
    }

    private enum Event: Sendable {
        case finished(Int, Result<Data, any Error>)
        case hedgeDue(Int)
        case budgetExhausted
    }

    private func request(for query: String, endpoint: URL) throws -> URLRequest {
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw ClientError.invalidQuery
        }
        components.queryItems = [URLQueryItem(name: "data", value: query)]

        guard let url = components.url else {
            throw ClientError.invalidQuery
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = self.requestTimeout
        request.setValue(
            "TourismBeats/1.0 (\(Bundle.main.bundleIdentifier ?? "tourism-beats"))",
            forHTTPHeaderField: "User-Agent"
        )
        return request
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await self.transport(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            throw ClientError.httpStatus(httpResponse.statusCode)
        }

        return data
    }
}
