import CoreLocation
import Foundation
import Testing
@testable import Tourism_Beats

struct CityFunFactServiceTests {
    @Test func aStateOrProvinceLeadsTheArticleTitles() {
        let city = Self.city("Lehi", administrativeArea: "Utah")

        #expect(CityFunFactService.initialTitles(for: city).first == "Lehi, Utah")
    }

    /// Okanagan has no "Okanagan, British Columbia" article, so its plain title must stay reachable.
    @Test func thePlainNameStaysAsAFallback() {
        let city = Self.city("Okanagan", administrativeArea: "British Columbia")

        #expect(CityFunFactService.initialTitles(for: city).contains("Okanagan"))
    }

    @Test func aPinnedArticleIsTheOnlyTitleTried() {
        let city = Self.city(
            "Chail",
            administrativeArea: "Himachal Pradesh",
            wikipediaTitle: "Chail, Himachal Pradesh"
        )

        #expect(CityFunFactService.initialTitles(for: city) == ["Chail, Himachal Pradesh"])
    }

    @Test func citiesWithoutAStateStartFromTheirName() {
        #expect(CityFunFactService.initialTitles(for: Self.city("Tema")).first == "Tema")
    }

    @Test func curatedFactsLeadTheLookedUpOnes() {
        let curated = Self.fact("Curated")
        let lookedUp = Self.fact("Looked up")

        #expect(CityFunFactService.combined(curated: [curated], lookedUp: [lookedUp]) == [curated, lookedUp])
    }

    @Test func curatedFactsReplaceTheGenericFallback() {
        let curated = Self.fact("Curated")
        let fallback = Self.fact("Fallback", isFallback: true)

        #expect(CityFunFactService.combined(curated: [curated], lookedUp: [fallback]) == [curated])
    }

    @Test func aCityWithNoCuratedFactsKeepsTheFallback() {
        let fallback = Self.fact("Fallback", isFallback: true)

        #expect(CityFunFactService.combined(curated: [], lookedUp: [fallback]) == [fallback])
    }

    @MainActor
    @Test func nancyTellsTheOriginOfQuiche() throws {
        let nancy = try #require(DataService().loadCities().first { $0.id == "Nancy-FR" })

        #expect(nancy.curatedFunFacts.contains { $0.text.localizedStandardContains("quiche") })
    }

    @Test func curatedFactsAreToldWithoutASource() {
        let fact = CityFunFact.curated("Nancy may be where quiche began.")

        #expect(fact.sourceName == nil)
        #expect(fact.sourceURL == nil)
        #expect(!fact.isFallback)
    }

    @MainActor
    @Test func theCatalogPlacesUtahCitiesByTheirState() throws {
        let lehi = try #require(DataService().loadCities().first { $0.id == "Lehi-US" })

        #expect(lehi.displayName == "Lehi, Utah")
    }

    private static func fact(_ text: String, isFallback: Bool = false) -> CityFunFact {
        CityFunFact(text: text, sourceName: "Source", sourceURL: nil, isFallback: isFallback)
    }

    private static func city(
        _ name: String,
        administrativeArea: String? = nil,
        wikipediaTitle: String? = nil
    ) -> CityModel {
        CityModel(
            id: name,
            name: name,
            country: CountryModel(name: "Testland", code: "TT", flag: ""),
            administrativeArea: administrativeArea,
            imageURL: URL.documentsDirectory,
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            timeZoneIdentifier: "UTC",
            wikipediaTitle: wikipediaTitle
        )
    }
}
