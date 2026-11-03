import Foundation
import Testing
@testable import Tourism_Beats

@MainActor
struct FlightCountdownTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func flight(after interval: TimeInterval = 3_600) -> CountdownFlight {
        CountdownFlight(
            airlineCode: "AC", flightNumber: "123", origin: "YVR", destination: "YYZ",
            departure: now.addingTimeInterval(interval), timeZoneIdentifier: "America/Vancouver"
        )
    }

    @Test func nextFlightSkipsDepartedFlightsAndAdvancesAtDeparture() {
        let first = flight(after: 60)
        let second = flight(after: 120)
        let flights = [second, flight(after: -60), first]
        #expect(CountdownFlight.next(in: flights, after: now) == first)
        #expect(CountdownFlight.next(in: flights, after: first.departure) == second)
        #expect(CountdownFlight.next(in: flights, after: second.departure) == nil)
    }

    @Test func widgetTimelineIncludesExactDeparturesAndFutureCoverage() {
        let first = flight(after: 65)
        let second = flight(after: 950)
        let dates = FlightCountdownSchedule.dates(for: [second, first], from: now)
        #expect(dates.first == now)
        #expect(dates.contains(first.departure))
        #expect(dates.contains(second.departure))
        #expect(dates.last == now.addingTimeInterval(FlightCountdownSchedule.horizon))
        #expect(dates == dates.sorted())
        #expect(Set(dates).count == dates.count)
        #expect(CountdownFlight.next(in: [first, second], after: first.departure) == second)
    }

    @Test func departureIsAnAbsoluteInstantAcrossTimeZones() {
        var value = flight()
        let date = value.departure
        value.timeZoneIdentifier = "Asia/Tokyo"
        #expect(value.departure == date)
        #expect(value.timeZone.identifier == "Asia/Tokyo")
        #expect(value.departureLabel != flight().departureLabel)
    }

    @Test func formBuildsAFlightFromChoicesAndRejectsInvalidRoutes() throws {
        let airports = AirportDirectory.bundled
        let form = FlightCountdownFormViewModel(flight: flight())
        #expect(!form.hasChanges)
        #expect(form.airline?.name == "Air Canada")
        form.flightNumber = " 45a6 78"
        #expect(form.flightNumber == "4567")
        form.select(destination: try #require(airports.airport(code: "LHR")))
        #expect(form.canSave)
        #expect(form.hasChanges)
        #expect(form.flight.designator == "AC 4567")
        #expect(form.flight.airlineName == "Air Canada")
        #expect(form.flight.destinationCity == "London")
        form.select(destination: try #require(airports.airport(code: "YVR")))
        #expect(!form.canSave)
        form.select(destination: .unlisted(code: "XYZ"))
        #expect(form.canSave)
        #expect(form.flight.destinationCity == nil)
        form.flightNumber = ""
        #expect(!form.canSave)
    }

    @Test func newFormNeedsEveryChoiceAndCountsOnlyRealInputAsChanges() throws {
        let form = FlightCountdownFormViewModel(now: now)
        #expect(!form.hasChanges)
        #expect(!form.canSave)
        #expect(form.departure > now)
        form.select(airline: .unlisted(code: "ZZ"))
        #expect(form.hasChanges)
        form.flightNumber = "1"
        form.select(origin: try #require(AirportDirectory.bundled.airport(code: "YVR")))
        form.select(destination: try #require(AirportDirectory.bundled.airport(code: "YUL")))
        #expect(form.canSave)
        #expect(form.flight.airlineName == nil)
        #expect(form.flight.countdownStartedAt == now)
    }

    @Test func choosingADepartureAirportKeepsTheClockTimeInItsZone() throws {
        let form = FlightCountdownFormViewModel(now: now)
        form.setTimeZone("America/Toronto")
        var toronto = Calendar(identifier: .gregorian)
        toronto.timeZone = try #require(TimeZone(identifier: "America/Toronto"))
        form.departure = try #require(toronto.date(from: DateComponents(year: 2026, month: 12, day: 20, hour: 13, minute: 50)))
        form.select(origin: try #require(AirportDirectory.bundled.airport(code: "YVR")))
        #expect(form.timeZoneIdentifier == "America/Vancouver")
        var vancouver = Calendar(identifier: .gregorian)
        vancouver.timeZone = form.timeZone
        let clock = vancouver.dateComponents([.month, .day, .hour, .minute], from: form.departure)
        #expect(clock == DateComponents(month: 12, day: 20, hour: 13, minute: 50))
        #expect(form.departureFooter.contains("Vancouver"))
    }

    @Test func countdownNeverShowsZeroForAnUpcomingFlight() {
        let soon = FlightCountdownText.components(until: now.addingTimeInterval(1), from: now)
        #expect(soon == [.init(value: 0, unit: .hour), .init(value: 1, unit: .minute)])
        #expect(FlightCountdownText.remaining(until: now, from: now) == "Scheduled departure passed")
    }

    @Test func storeRoundTripsEditsAndDeletionsAcrossInstances() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FlightCountdownStore(directory: directory)
        #expect(try await store.load().isEmpty)
        let original = flight()
        try await store.save([original])
        #expect(try await FlightCountdownStore(directory: directory).load() == [original])
        var edited = original
        edited.flightNumber = "456"
        try await store.save([edited])
        #expect(try await store.load() == [edited])
        try await store.save([])
        #expect(try await store.load().isEmpty)
    }

    @Test func corruptStorageIsReportedInsteadOfOverwritten() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "flight-countdowns.json")
        let corrupt = Data("invalid".utf8)
        try corrupt.write(to: url)
        let model = FlightCountdownViewModel(store: FlightCountdownStore(directory: directory), reloadWidget: {})
        await model.load()
        #expect(!model.hasLoaded)
        #expect(model.errorMessage != nil)
        #expect(await model.save(flight()) == false)
        #expect(try Data(contentsOf: url) == corrupt)
    }

    @Test func failedSavePreservesFlightsAndDoesNotReloadWidget() async {
        let original = flight()
        let store = FailingFlightStore(flights: [original])
        var reloadCount = 0
        let model = FlightCountdownViewModel(store: store, reloadWidget: { reloadCount += 1 })
        await model.load()
        #expect(await model.delete(original) == false)
        #expect(model.flights == [original])
        #expect(reloadCount == 0)
        #expect(model.errorMessage != nil)
    }

    @Test func successfulChangesReloadWidgetAndKeepStableIdentity() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        var reloadCount = 0
        let model = FlightCountdownViewModel(
            store: FlightCountdownStore(directory: directory), reloadWidget: { reloadCount += 1 }
        )
        await model.load()
        var value = flight()
        #expect(await model.save(value))
        value.destination = "LHR"
        #expect(await model.save(value))
        #expect(model.flights == [value])
        #expect(await model.delete(value))
        #expect(model.flights.isEmpty)
        #expect(reloadCount == 3)
    }
}
