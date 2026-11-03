import Foundation
import Testing
@testable import Tourism_Beats

@MainActor
struct FlightCountdownTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func flight(after interval: TimeInterval = 3_600) -> CountdownFlight {
        CountdownFlight(
            flightNumber: "AC 123", origin: "YVR", destination: "YYZ",
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

    @Test func formNormalizesInputAndRejectsInvalidRoutes() {
        let form = FlightCountdownFormViewModel(flight: flight())
        #expect(!form.hasChanges)
        form.flightNumber = " ac 456 "
        form.origin = " yvr "
        form.destination = "lhr"
        #expect(form.canSave)
        #expect(form.flight.flightNumber == "AC 456")
        #expect(form.flight.origin == "YVR")
        #expect(form.flight.destination == "LHR")
        #expect(form.hasChanges)
        form.destination = " yvr "
        #expect(!form.canSave)
        form.destination = "123"
        #expect(!form.canSave)
        form.destination = "Vancouver"
        #expect(!form.canSave)
        form.destination = "YYZ"
        form.timeZoneIdentifier = "Invalid/Zone"
        #expect(!form.canSave)
    }

    @Test func countdownNeverShowsZeroForAnUpcomingFlight() {
        #expect(FlightCountdownText.remaining(until: now.addingTimeInterval(1), from: now) == Duration.seconds(60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated, maximumUnitCount: 2)))
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
        edited.flightNumber = "AC 456"
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
