import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - RestaurantCuisineLabelerTests

struct RestaurantCuisineLabelerTests {
    @Test func onlyMissingCuisinesAreFilledIn() async {
        let restaurants = [
            TripPlanningFixtures.restaurant("Scala Osteria", cuisine: "Italian"),
            TripPlanningFixtures.restaurant("The French Laundry", cuisine: nil),
            TripPlanningFixtures.restaurant("Eiko's", cuisine: nil),
        ]
        let classifier = StubClassifier(answers: [
            "The French Laundry": "French",
            "Scala Osteria": "Pizza",
        ])

        let labelled = await RestaurantCuisineLabeler.label(
            restaurants,
            in: TripPlanningFixtures.portOfSpain,
            using: classifier
        )

        #expect(labelled.map(\.cuisine) == ["Italian", "French", nil])
        #expect(await classifier.askedNames() == ["The French Laundry", "Eiko's"])
    }

    @Test func aFullyLabelledGuideIsNotSentToTheClassifier() async {
        let restaurants = [TripPlanningFixtures.restaurant("Celadon", cuisine: "American")]
        let classifier = StubClassifier(answers: [:])

        _ = await RestaurantCuisineLabeler.label(restaurants, in: TripPlanningFixtures.portOfSpain, using: classifier)

        #expect(await classifier.askedNames().isEmpty)
    }
}

// MARK: - OnDeviceRestaurantCuisineClassifierTests

struct OnDeviceRestaurantCuisineClassifierTests {
    private let restaurants = [
        TripPlanningFixtures.restaurant("ZuZu", cuisine: nil),
        TripPlanningFixtures.restaurant("Celadon", cuisine: nil),
        TripPlanningFixtures.restaurant("Eiko's", cuisine: nil),
    ]

    @Test func answersMapBackByNumberAndUnknownIsDropped() {
        let generated = GeneratedRestaurantCuisines(restaurants: [
            GeneratedRestaurantCuisine(number: 1, cuisine: "Tapas"),
            GeneratedRestaurantCuisine(number: 2, cuisine: OnDeviceRestaurantCuisineClassifier.unknown),
            GeneratedRestaurantCuisine(number: 3, cuisine: "Japanese"),
            GeneratedRestaurantCuisine(number: 9, cuisine: "Thai"),
        ])

        let labels = OnDeviceRestaurantCuisineClassifier.labels(from: generated, for: self.restaurants)

        #expect(labels == [self.restaurants[0].id: "Tapas", self.restaurants[2].id: "Japanese"])
    }

    @Test func answersOutsideTheVocabularyAreDropped() {
        let generated = GeneratedRestaurantCuisines(restaurants: [
            GeneratedRestaurantCuisine(number: 1, cuisine: "Amazing Food"),
        ])

        #expect(OnDeviceRestaurantCuisineClassifier.labels(from: generated, for: self.restaurants).isEmpty)
    }

    @Test func thePromptNumbersEachRestaurantWithItsClues() {
        let prompt = OnDeviceRestaurantCuisineClassifier.prompt(
            for: self.restaurants,
            in: TripPlanningFixtures.portOfSpain
        )

        #expect(prompt.contains("Restaurants in Port of Spain, Trinidad and Tobago:"))
        #expect(prompt.contains("1. ZuZu (ZuZu Street)"))
        #expect(prompt.contains("3. Eiko's (Eiko's Street)"))
    }
}

// MARK: - StubClassifier

private actor StubClassifier: RestaurantCuisineClassifying {
    private let answers: [String: String]
    private var asked: [String] = []

    init(answers: [String: String]) {
        self.answers = answers
    }

    func cuisines(for restaurants: [CityRestaurant], in _: CityModel) async -> [CityRestaurant.ID: String] {
        self.asked += restaurants.map(\.name)
        return restaurants.reduce(into: [:]) { labels, restaurant in
            labels[restaurant.id] = self.answers[restaurant.name]
        }
    }

    func askedNames() -> [String] {
        self.asked
    }
}
