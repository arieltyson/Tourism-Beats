import CoreGraphics
import Foundation

// MARK: - HomeViewModel

/// Feeds the home carousel an endless run of featured cities in both
/// directions, dealt from a shuffled deck of every eligible city so each
/// swipe, left or right, brings somewhere new.
///
/// Cards are numbered by position, negative to the left of the first one, and
/// dealt only as a swipe nears them, so there is no first or last card.
@MainActor @Observable
final class HomeViewModel {
    /// How many cards either side of the centre are drawn.
    static let visibleRadius = 2
    /// How many cards either side of the centre are kept dealt, a little past
    /// the visible ones so a fast swipe never reaches an empty slot.
    static let dealtRadius = 6

    private(set) var citiesByPosition: [Int: CityModel] = [:]
    private(set) var isLoaded = false

    /// How many cards either side of the centre have their photos loaded
    /// ahead of time, so a swipe reveals a photo rather than a placeholder.
    static let prefetchRadius = visibleRadius + 1

    private var deck = HomeCityDeck(cities: [])
    /// Starts loading photos for cards about to appear.
    @ObservationIgnored var prefetchImages: @Sendable ([URL]) -> Void = { ImagePipeline.shared.prefetch($0) }
    private var lowestDealtPosition = 0
    private var highestDealtPosition = -1

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    /// How many different cities the carousel can show.
    var featuredCityCount: Int { self.deck.cityCount }

    func loadCities(using dataService: DataService = DataService()) {
        guard !self.isLoaded else { return }
        guard let cities = try? dataService.loadCities() else { return }
        self.load(cities: cities)
    }

    func load(cities: [CityModel]) {
        let featuredPool = cities.filter(\.isEligibleForFeaturedHeroCarousel)
        self.deck = HomeCityDeck(cities: featuredPool.isEmpty ? cities : featuredPool)
        self.citiesByPosition = [:]
        self.lowestDealtPosition = 0
        self.highestDealtPosition = -1
        self.dealCities(around: 0)
        self.isLoaded = !self.citiesByPosition.isEmpty
    }

    /// Deals cities for every position within reach of `position`, on
    /// whichever side the carousel is heading.
    func dealCities(around position: Int) {
        let highest = position + Self.dealtRadius
        if highest > self.highestDealtPosition {
            let cities = self.deck.deal(highest - self.highestDealtPosition)
            for (offset, city) in cities.enumerated() {
                self.citiesByPosition[self.highestDealtPosition + 1 + offset] = city
            }
            self.highestDealtPosition = highest
        }

        let lowest = position - Self.dealtRadius
        if lowest < self.lowestDealtPosition {
            let cities = self.deck.deal(self.lowestDealtPosition - lowest)
            for (offset, city) in cities.enumerated() {
                self.citiesByPosition[self.lowestDealtPosition - 1 - offset] = city
            }
            self.lowestDealtPosition = lowest
        }

        let nearby = (position - Self.prefetchRadius ... position + Self.prefetchRadius)
            .compactMap { self.citiesByPosition[$0]?.imageURL }
        self.prefetchImages(nearby)
    }

    /// The cards to draw for a carousel resting or moving at `position`,
    /// where a whole number is a card in the centre.
    func visibleItems(around position: CGFloat) -> [HomeCarouselItem] {
        let low = Int((position - CGFloat(Self.visibleRadius)).rounded(.down))
        let high = Int((position + CGFloat(Self.visibleRadius)).rounded(.up))
        return (low ... high).compactMap { index in
            self.citiesByPosition[index].map { HomeCarouselItem(id: index, city: $0) }
        }
    }

    func localTime(for city: CityModel, at date: Date = .now) -> String {
        self.timeFormatter.timeZone = city.timeZone
        return self.timeFormatter.string(from: date)
    }
}
