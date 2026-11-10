import Testing
@testable import Tourism_Beats

@MainActor
struct FoodViewModelShowcaseTests {
    @Test func aShowcaseReplacesTheJournalUntilAFilterIsChosen() {
        let model = FoodViewModel()
        #expect(!model.isNarrowed && model.visibleShowcase == nil)

        model.select(.topCuisines)
        #expect(model.visibleShowcase == .topCuisines && model.isNarrowed)

        model.select(.gastroCities)
        #expect(model.visibleShowcase == .gastroCities)

        model.select(.tried)
        #expect(model.selectedShowcase == nil && model.selectedFilter == .tried)

        model.select(nil)
        #expect(!model.isNarrowed)
    }

    @Test func searchingReturnsToTheJournal() {
        let model = FoodViewModel()
        model.select(.gastroCities)
        model.searchText = "Lisbon"
        #expect(model.visibleShowcase == nil)
        model.searchText = ""
        #expect(model.visibleShowcase == .gastroCities)
    }

    @Test func everyRankedGastroCityOpensACatalogCity() {
        let model = FoodViewModel()
        #expect(model.gastroCities.count == GastroCityRanking.top.count)
        for featured in model.gastroCities {
            #expect(featured.city.name == featured.ranking.name)
            #expect(featured.city.country.code == featured.ranking.countryCode)
        }
    }

    @Test func aRankedCityMissingFromTheCatalogIsLeftOut() {
        let unknown = GastroCity(rank: 1, name: "Atlantis", countryCode: "XX", distinction: .worldsFiftyBest(1))
        let model = FoodViewModel(gastroRanking: [unknown])
        #expect(model.gastroCities.isEmpty)
    }
}
