import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - SafetyCoverageTests

/// The Global Peace Index ranks 163 countries. Territories it leaves out take
/// their governing country's index; the small states it leaves out are said
/// to be unranked rather than shown as a failure.
@MainActor
struct SafetyCoverageTests {
    private struct StubSafetyService: SafetyProtocol {
        let entries: [String: SafetyModel]

        func fetchSafetyData(for countryCode: String) async throws -> SafetyModel {
            guard let entry = self.entries[countryCode] else { throw SafetyError.countryNotFound }
            return entry
        }
    }

    private static func city(code: String, name: String) -> CityModel {
        CityModel(
            id: "city-\(code.lowercased())",
            name: "Capital",
            country: CountryModel(name: name, code: code, flag: ""),
            imageURL: URL(string: "https://example.com/city.jpg")!,
            coordinate: TripPlanningFixtures.portOfSpain.coordinate,
            timeZoneIdentifier: "UTC"
        )
    }

    private static let france = SafetyModel(
        countryName: "France", countryCode: "FR", region: "Europe",
        rank: 74, score: 1.9, rankChange: 0, scoreChange: 0
    )

    @Test func aTerritoryNamesTheCountryWhoseIndexItShows() async {
        // The service answers Martinique with France's entry.
        let viewModel = SafetyViewModel(
            city: Self.city(code: "MQ", name: "Martinique"),
            safetyService: StubSafetyService(entries: ["MQ": Self.france])
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.governingCountryName == "France")
        #expect(viewModel.sourceLabel == "Global Peace Index 2026 · France")
    }

    @Test func aCountryWithItsOwnIndexNamesNoOther() async {
        let viewModel = SafetyViewModel(
            city: Self.city(code: "FR", name: "France"),
            safetyService: StubSafetyService(entries: ["FR": Self.france])
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.governingCountryName == nil)
        #expect(viewModel.sourceLabel == "Global Peace Index 2026")
    }

    @Test func anUnrankedCountryIsNotAFailureAndIsNotAskedForAgain() async {
        let viewModel = SafetyViewModel(
            city: Self.city(code: "BS", name: "Bahamas"),
            safetyService: StubSafetyService(entries: [:])
        )

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(viewModel.isUnranked)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.safetyData == nil)
    }

    @Test func everyTerritoryInTheBundleTakesARankedCountrysIndex() async throws {
        let url = try #require(Bundle.main.url(forResource: "gpi_governing_countries", withExtension: "json"))
        let governing = try JSONDecoder().decode([String: String].self, from: Data(contentsOf: url))
        let service = SafetyService()

        for (territory, country) in governing {
            let entry = try await service.fetchSafetyData(for: territory)
            #expect(entry.countryCode == country, "\(territory) should show \(country)'s index")
        }
    }

    @Test func everyCatalogCountryIsRankedGovernedOrKnownToBeUnranked() async throws {
        // The independent states the 2026 index doesn't rank.
        let unranked: Set<String> = [
            "AD", "AG", "BB", "BN", "BS", "BZ", "CV", "DM", "FJ", "FM", "GD", "KI", "KM", "KN",
            "LC", "LI", "LU", "MC", "MH", "MT", "MV", "NR", "PW", "SB", "SC", "SM", "SR", "ST",
            "TO", "TV", "VA", "VC", "VU", "WS"
        ]
        let service = SafetyService()
        let cityCountries = Set(try DataService().loadCities().map(\.country.code))

        for code in cityCountries {
            do {
                _ = try await service.fetchSafetyData(for: code)
                #expect(!unranked.contains(code), "\(code) is listed as unranked but has an index")
            } catch SafetyError.countryNotFound {
                #expect(unranked.contains(code), "\(code) has neither an index nor a governing country")
            }
        }
    }
}
