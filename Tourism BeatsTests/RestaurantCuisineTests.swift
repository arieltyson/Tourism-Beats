import Testing
@testable import Tourism_Beats

// MARK: - RestaurantCuisineTests

struct RestaurantCuisineTests {
    @Test func drinksCoverCoffeeTeaJuiceAndBubbleTea() {
        let drinks = RestaurantCuisine.allCases.filter { $0.category == .drinks }

        #expect(Set(drinks) == [.bar, .bubbleTea, .cafe, .coffee, .juice, .tea])
    }

    @Test func persistedRawValuesStayStable() {
        #expect(RestaurantCuisine(rawValue: "cafe") == .cafe)
        #expect(RestaurantCuisine(rawValue: "middleEastern") == .middleEastern)
        #expect(RestaurantCuisine(rawValue: "coffee") == .coffee)
    }

    @Test func everyCuisineHasAUniqueLabel() {
        let labels = RestaurantCuisine.allCases.map(\.label)

        #expect(Set(labels).count == labels.count)
    }
}
