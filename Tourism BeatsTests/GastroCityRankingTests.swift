import Testing
@testable import Tourism_Beats

struct GastroCityRankingTests {
    @Test func theTopFifteenAreRankedInOrder() {
        let cities = GastroCityRanking.top
        #expect(cities.map(\.rank) == Array(1...15))
        #expect(Set(cities.map(\.name)).count == cities.count)
        #expect(cities.first?.name == "Tokyo")
    }

    @Test func theGastronomicCapitalsAreAmongThem() {
        let names = Set(GastroCityRanking.top.map(\.name))
        #expect(names.isSuperset(of: ["Lyon", "San Sebastián", "Paris", "Kyoto"]))
    }

    @Test func everyCityStatesWhatEarnsItsPlace() {
        for city in GastroCityRanking.top {
            #expect(!city.distinction.text.isEmpty && !city.distinction.systemImage.isEmpty)
            #expect(city.countryCode.count == 2)
        }
    }

    @Test @MainActor func eachCardIsSpokenAsOne() throws {
        let tokyo = try #require(FoodViewModel().gastroCities.first)
        let label = tokyo.accessibilityLabel
        #expect(label.contains("1") && label.contains("Tokyo") && label.contains("Japan") && label.contains("160"))
    }
}
