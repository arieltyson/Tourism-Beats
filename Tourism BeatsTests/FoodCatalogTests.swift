import Foundation
import Testing
@testable import Tourism_Beats

@MainActor
struct FoodCatalogTests {
    /// The bundled catalog is built once and shared, so creating the Food
    /// tab again costs nothing.
    @Test func bundledCatalogIsSortedForChoosing() {
        let catalog = FoodCatalog.bundled
        #expect(!catalog.places.isEmpty)
        #expect(zip(catalog.places, catalog.places.dropFirst()).allSatisfy {
            $0.city.localizedStandardCompare($1.city) != .orderedDescending
        })
        #expect(zip(catalog.countries, catalog.countries.dropFirst()).allSatisfy {
            $0.name.localizedStandardCompare($1.name) != .orderedDescending
        })
    }
}
