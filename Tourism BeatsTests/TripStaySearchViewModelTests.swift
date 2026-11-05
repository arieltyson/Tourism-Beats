import Foundation
import Testing
@testable import Tourism_Beats

@MainActor
struct TripStaySearchViewModelTests {
    private struct StubSearch: TripStaySearching {
        var stays: [TripStay] = []
        var fails = false

        func stays(matching query: String, in area: TripStaySearchArea) async throws -> [TripStay] {
            if self.fails { throw URLError(.notConnectedToInternet) }
            return query.isEmpty ? self.stays : self.stays.filter { $0.name.localizedStandardContains(query) }
        }
    }

    private let area = TripStaySearchArea(cityName: "Lisbon", countryName: "Portugal")
    private let stays = [
        TripStay(name: "Bairro Alto Hotel", address: "Praça Luís de Camões", latitude: 38.711, longitude: -9.143),
        TripStay(name: "Memmo Alfama", address: nil, latitude: 38.711, longitude: -9.130)
    ]

    @Test func anEmptyQueryListsTheCitysHotels() async {
        let model = TripStaySearchViewModel(area: self.area, service: StubSearch(stays: self.stays))
        await model.search()
        #expect(model.results == self.stays)
        #expect(!model.isSearching && !model.didFail)
    }

    @Test func typingNarrowsTheResults() async {
        let model = TripStaySearchViewModel(area: self.area, service: StubSearch(stays: self.stays))
        model.query = "  memmo "
        await model.search()
        #expect(model.results.map(\.name) == ["Memmo Alfama"])
    }

    @Test func aFailedSearchSaysSoAndShowsNothing() async {
        let model = TripStaySearchViewModel(area: self.area, service: StubSearch(fails: true))
        await model.search()
        #expect(model.results.isEmpty && model.didFail)
    }

    @Test func aTripRemembersItsStay() throws {
        let trip = Trip(name: "Lisbon", city: "Lisbon")
        #expect(trip.stay == nil)
        trip.stay = self.stays[0]
        #expect(trip.stay == self.stays[0])
        trip.stay = nil
        #expect(trip.stayName == nil && trip.stayLatitude == nil && trip.stayLongitude == nil)
    }
}
