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

    private static func fact(_ text: String, isFallback: Bool = false) -> CityFunFact {
        CityFunFact(text: text, sourceName: "Source", sourceURL: nil, isFallback: isFallback)
    }

    private static func city(_ name: String, administrativeArea: String? = nil) -> CityModel {
        CityModel(
            id: name,
            name: name,
            country: CountryModel(name: "Testland", code: "TT", flag: ""),
            administrativeArea: administrativeArea,
            imageURL: URL.documentsDirectory,
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            timeZoneIdentifier: "UTC"
        )
    }
}
