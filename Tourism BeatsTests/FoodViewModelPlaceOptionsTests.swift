import SwiftData
import Testing
@testable import Tourism_Beats

// MARK: - FoodViewModelPlaceOptionsTests

@Suite(.serialized)
@MainActor
struct FoodViewModelPlaceOptionsTests {
    @Test func journalPlacesComeFirstOnceEachInTheGivenOrder() throws {
        let container = try Self.makeInMemoryContainer()
        let restaurants = [
            Restaurant(name: "Mon Ami Gabi", city: "Las Vegas", country: "United States"),
            Restaurant(name: "Il Terrazzo", city: "Victoria", country: "Canada"),
            Restaurant(name: "Lotus of Siam", city: " Las Vegas ", country: "United States"),
        ]
        restaurants.forEach(container.mainContext.insert)

        let options = FoodViewModel().placeOptions(from: restaurants)

        #expect(options.journalPlaces.map(\.city) == ["Las Vegas", "Victoria"])
        #expect(options.journalPlaces.first?.flag == "🇺🇸")
    }

    @Test func aJournalPlaceReplacesItsCatalogCityKeepingTheJournalSpelling() throws {
        let container = try Self.makeInMemoryContainer()
        let restaurant = Restaurant(name: "Mon Ami Gabi", city: "Las Vegas", country: "United States")
        container.mainContext.insert(restaurant)

        let options = FoodViewModel().placeOptions(from: [restaurant])
        let lasVegas = options.places(matching: "Las Vegas").filter { $0.city == "Las Vegas" }

        #expect(lasVegas.map(\.country) == ["United States"])
        #expect(!options.catalogPlaces.contains { $0.city == "Las Vegas" })
    }

    @Test func catalogOffersEveryCountry() {
        let options = FoodViewModel().placeOptions(from: [])

        #expect(options.journalPlaces.isEmpty)
        #expect(options.countries.contains { $0.code == "GF" })
        #expect(options.catalogPlaces.contains { $0.city == "Monterrey" && $0.country == "Mexico" })
    }

    private static func makeInMemoryContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Restaurant.self,
            RestaurantMealPhoto.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
