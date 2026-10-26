import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - OverpassClientTests

struct OverpassClientTests {
    @Test func refusalFailsOverToNextInstanceWithoutWaitingForHedge() async throws {
        let transport = ScriptedTransport(["primary": .status(502), "mirror": .body("mirror")])
        let client = Self.makeClient(transport: transport, hedgeDelay: .seconds(30))

        let data = try await client.data(for: "node;out;")

        #expect(String(decoding: data, as: UTF8.self) == "mirror")
        #expect(await transport.requestedHosts() == ["primary", "mirror"])
    }

    @Test func slowInstanceIsHedgedByTheNextOne() async throws {
        let transport = ScriptedTransport(["primary": .stall, "mirror": .body("mirror")])
        let client = Self.makeClient(transport: transport, hedgeDelay: .milliseconds(50))
        let clock = ContinuousClock()

        let start = clock.now
        let data = try await client.data(for: "node;out;")

        #expect(String(decoding: data, as: UTF8.self) == "mirror")
        #expect(clock.now - start < .seconds(5))
    }

    @Test func fastSuccessNeverContactsOtherInstances() async throws {
        let transport = ScriptedTransport(["primary": .body("primary"), "mirror": .body("mirror")])
        let client = Self.makeClient(transport: transport, hedgeDelay: .seconds(30))

        let data = try await client.data(for: "node;out;")

        #expect(String(decoding: data, as: UTF8.self) == "primary")
        #expect(await transport.requestedHosts() == ["primary"])
    }

    @Test func throwsLastErrorWhenEveryInstanceFails() async {
        let transport = ScriptedTransport(["primary": .status(502), "mirror": .status(429)])
        let client = Self.makeClient(transport: transport, hedgeDelay: .seconds(30))

        await #expect(throws: OverpassClient.ClientError.self) {
            try await client.data(for: "node;out;")
        }
        #expect(await transport.requestedHosts() == ["primary", "mirror"])
    }

    @Test func givesUpWhenTheTimeBudgetRunsOut() async {
        let transport = ScriptedTransport(["primary": .stall, "mirror": .stall])
        let client = Self.makeClient(
            transport: transport,
            hedgeDelay: .milliseconds(20),
            timeBudget: .milliseconds(150)
        )
        let clock = ContinuousClock()

        let start = clock.now
        await #expect(throws: OverpassClient.ClientError.timeBudgetExceeded) {
            try await client.data(for: "node;out;")
        }
        #expect(clock.now - start < .seconds(5))
    }

    @Test func outageCoolsDownBeforeTheNetworkIsTriedAgain() async {
        let transport = ScriptedTransport(["primary": .status(502), "mirror": .status(504)])
        let availability = OverpassAvailability(cooldown: .seconds(60))
        let client = Self.makeClient(
            transport: transport,
            hedgeDelay: .seconds(30),
            availability: availability
        )

        await #expect(throws: OverpassClient.ClientError.self) {
            try await client.data(for: "node;out;")
        }
        await #expect(throws: OverpassClient.ClientError.coolingDown) {
            try await client.data(for: "node;out;")
        }
        #expect(await transport.requestedHosts() == ["primary", "mirror"])
    }

    private static func makeClient(
        transport: ScriptedTransport,
        hedgeDelay: Duration,
        timeBudget: Duration = .seconds(30),
        availability: OverpassAvailability = OverpassAvailability()
    ) -> OverpassClient {
        OverpassClient(
            endpoints: [
                URL(string: "https://primary/api/interpreter"),
                URL(string: "https://mirror/api/interpreter")
            ]
            .compactMap(\.self),
            hedgeDelay: hedgeDelay,
            timeBudget: timeBudget,
            availability: availability,
            transport: { request in try await transport.respond(to: request) }
        )
    }
}

// MARK: - ScriptedTransport

private actor ScriptedTransport {
    enum Reply: Sendable {
        case body(String)
        case status(Int)
        case stall
    }

    private let replies: [String: Reply]
    private var hosts: [String] = []

    init(_ replies: [String: Reply]) {
        self.replies = replies
    }

    func requestedHosts() -> [String] {
        self.hosts
    }

    func respond(to request: URLRequest) async throws -> (Data, URLResponse) {
        let url = try #require(request.url)
        let host = url.host() ?? ""
        self.hosts.append(host)

        switch self.replies[host] {
        case let .body(text):
            return (Data(text.utf8), Self.response(for: url, status: 200))
        case let .status(code):
            return (Data(), Self.response(for: url, status: code))
        case nil, .stall:
            try await Task.sleep(for: .seconds(60))
            throw CancellationError()
        }
    }

    private static func response(for url: URL, status: Int) -> URLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) ?? URLResponse()
    }
}
