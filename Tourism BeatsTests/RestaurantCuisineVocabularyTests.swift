import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - RestaurantCuisineVocabularyTests

struct RestaurantCuisineVocabularyTests {
    @Test(arguments: [
        ("italian;pizza", "Italian"),
        ("coffee_shop", "Coffee"),
        ("regional;french", "French"),
        ("Italian • Pizza", "Italian"),
        ("steak_house", "Steakhouse"),
        ("BBQ", "Barbecue"),
        ("fine_dining;seafood", "Seafood"),
        ("bubble_tea", "Bubble Tea"),
        ("creole", "Creole"),
        ("pacific_northwest", "Pacific Northwest"),
    ])
    func rawValuesBecomeOneConciseLabel(raw: String, expected: String) {
        #expect(RestaurantCuisineVocabulary.label(for: raw) == expected)
    }

    @Test func valuesThatSayNothingAboutTheFoodGiveNoLabel() {
        #expect(RestaurantCuisineVocabulary.label(for: "regional;fine_dining") == nil)
        #expect(RestaurantCuisineVocabulary.label(for: "  ") == nil)
        #expect(RestaurantCuisineVocabulary.label(for: nil) == nil)
    }

    @Test(arguments: [
        ("The French Laundry", "French"),
        ("Thai Basil Kitchen", "Thai"),
        ("Indiana Grill", nil),
        ("Germantown Diner", nil),
        ("Osteria Mozza", "Italian"),
    ] as [(String, String?)])
    func namesThatStateACuisineAreLabelled(name: String, expected: String?) {
        #expect(CuisineInferrer.infer(from: name) == expected)
    }

    @Test func labelsAreUniqueAndAlphabetical() {
        let labels = RestaurantCuisineVocabulary.labels

        #expect(Set(labels).count == labels.count)
        #expect(labels == labels.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }
}
