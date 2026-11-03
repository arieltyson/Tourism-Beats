import Foundation
import Testing
@testable import Tourism_Beats

struct FlightDirectoryTests {
    private let airports = AirportDirectory.bundled
    private let airlines = AirlineDirectory.bundled

    @Test func cityWithSeveralAirportsListsThemTogether() throws {
        let london = try #require(airports.results(matching: "London").first)
        #expect(london.city == "London")
        #expect(Set(london.airports.map(\.code)).isSuperset(of: ["LHR", "LGW", "STN", "LTN", "LCY"]))
        #expect(london.airports.first?.size == 0)
    }

    @Test(arguments: [("Tokyo", "NRT"), ("Washington", "IAD"), ("New York", "EWR"), ("Toronto", "YTZ")])
    func metropolitanAreasIncludeAirportsOutsideTheCity(city: String, code: String) throws {
        let group = try #require(airports.results(matching: city).first)
        #expect(group.city == city)
        #expect(group.airports.map(\.code).contains(code))
    }

    @Test func searchIgnoresDiacriticsAndCase() throws {
        let group = try #require(airports.results(matching: "montreal").first)
        #expect(group.airports.first?.code == "YUL")
    }

    @Test func exactCodeComesFirstAndCarriesItsTimeZone() throws {
        let group = try #require(airports.results(matching: "yvr").first)
        let airport = try #require(group.airports.first)
        #expect(airport.code == "YVR")
        #expect(airport.timeZone == "America/Vancouver")
        #expect(TimeZone(identifier: airport.timeZone ?? "") != nil)
    }

    @Test func everyListedAirportHasAValidCodeAndTimeZone() {
        #expect(airports.airports.count > 3_000)
        #expect(airports.airports.allSatisfy { Airport.isCode($0.code) })
        #expect(airports.airports.allSatisfy { TimeZone(identifier: $0.timeZone ?? "") != nil })
    }

    @Test func emptyQueryFindsNothing() {
        #expect(airports.results(matching: "  ").isEmpty)
    }

    @Test func airlinesAreFoundByNameOrCode() {
        #expect(airlines.results(matching: "Air Canada").first?.code == "AC")
        #expect(airlines.results(matching: "ua").first?.name == "United Airlines")
        #expect(airlines.results(matching: "jet").contains { $0.code == "B6" })
        #expect(airlines.airline(code: "ac")?.name == "Air Canada")
        #expect(airlines.results(matching: "").count == airlines.airlines.count)
    }

    @Test func codesAreValidatedLikeIATADesignators() {
        #expect(Airline.isCode("B6"))
        #expect(Airline.isCode("AC"))
        #expect(!Airline.isCode("12"))
        #expect(!Airline.isCode("ACA"))
        #expect(Airport.isCode("YVR"))
        #expect(!Airport.isCode("YV1"))
        #expect(airlines.airlines.allSatisfy { Airline.isCode($0.code) })
    }
}
