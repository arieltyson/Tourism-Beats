import Testing
@testable import Tourism_Beats

@MainActor
struct FoodViewModelTopCuisinesTests {
    @Test func topCuisinesReplaceTheJournalUntilAFilterIsChosen() {
        let model = FoodViewModel()
        #expect(!model.isNarrowed && !model.isShowingTopCuisines)

        model.selectTopCuisines()
        #expect(model.isShowingTopCuisines && model.isNarrowed)

        model.select(.tried)
        #expect(!model.showsTopCuisines && model.selectedFilter == .tried)

        model.select(nil)
        #expect(!model.isNarrowed)
    }

    @Test func searchingReturnsToTheJournal() {
        let model = FoodViewModel()
        model.selectTopCuisines()
        model.searchText = "Lisbon"
        #expect(!model.isShowingTopCuisines)
        model.searchText = ""
        #expect(model.isShowingTopCuisines)
    }
}
