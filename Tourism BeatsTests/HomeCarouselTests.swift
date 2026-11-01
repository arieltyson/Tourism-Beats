import CoreLocation
import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - HomeCarouselTests

@MainActor
struct HomeCarouselTests {
    @Test func theDeckShowsEveryCityOnceBeforeAnyRepeat() {
        let cities = Self.cities(count: 40)
        var deck = HomeCityDeck(cities: cities)
        var generator = SeededGenerator(seed: 7)

        let firstRound = deck.deal(cities.count, using: &generator)

        #expect(Set(firstRound.map(\.id)) == Set(cities.map(\.id)))
    }

    @Test func aNewShuffleNeverRepeatsTheCityJustShown() {
        let cities = Self.cities(count: 3)

        for seed in 0 ..< 200 {
            var deck = HomeCityDeck(cities: cities)
            var generator = SeededGenerator(seed: UInt64(seed))
            let run = deck.deal(30, using: &generator)

            for (previous, next) in zip(run, run.dropFirst()) {
                #expect(previous.id != next.id)
            }
        }
    }

    @Test func anEmptyDeckDealsNothing() {
        var deck = HomeCityDeck(cities: [])

        #expect(deck.deal(5).isEmpty)
    }

    @Test func theCarouselOpensWithNeighboursOnBothSides() {
        let viewModel = HomeViewModel()
        viewModel.load(cities: Self.cities(count: 50))

        #expect(viewModel.items.count == HomeViewModel.batchSize)
        #expect(viewModel.initialItemID == HomeViewModel.leadingCardCount)
        #expect(viewModel.featuredCityCount == 50)
    }

    @Test func swipingTowardTheEndDealsMoreCardsWithFreshIdentities() {
        let viewModel = HomeViewModel()
        viewModel.load(cities: Self.cities(count: 5))
        let firstBatch = viewModel.items

        viewModel.cardDidAppear(firstBatch[1])
        #expect(viewModel.items.count == HomeViewModel.batchSize)

        viewModel.cardDidAppear(firstBatch[firstBatch.count - HomeViewModel.prefetchDistance + 1])
        #expect(viewModel.items.count == HomeViewModel.batchSize * 2)
        #expect(Set(viewModel.items.map(\.id)).count == viewModel.items.count)
    }

    @Test func citiesThatOptOutAreNotFeatured() {
        let viewModel = HomeViewModel()
        let hidden = Self.city(index: 0, featured: false)
        viewModel.load(cities: [hidden] + Self.cities(count: 3, startingAt: 1))

        #expect(!viewModel.items.contains { $0.city.id == hidden.id })
    }

    // MARK: Fixtures

    private static func cities(count: Int, startingAt start: Int = 0) -> [CityModel] {
        (start ..< start + count).map { self.city(index: $0) }
    }

    private static func city(index: Int, featured: Bool? = nil) -> CityModel {
        CityModel(
            id: "city-\(index)",
            name: "City \(index)",
            country: CountryModel(name: "Country", code: "CC", flag: "🏳️"),
            imageURL: URL(string: "https://example.com/\(index).jpg")!,
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            timeZoneIdentifier: "UTC",
            featuredHeroEligibleOverride: featured
        )
    }
}

// MARK: - SeededGenerator

/// A small deterministic generator (SplitMix64) so shuffles repeat in tests.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        self.state &+= 0x9E37_79B9_7F4A_7C15
        var value = self.state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
