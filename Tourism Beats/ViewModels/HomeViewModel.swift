import Foundation

// MARK: - HomeViewModel

/// Feeds the home carousel an endless run of featured cities, dealt from a
/// shuffled deck of every eligible city so each swipe brings somewhere new.
@MainActor @Observable
final class HomeViewModel {
    /// Cards dealt at a time.
    static let batchSize = 12
    /// Cards dealt ahead of the first visible one, so the carousel opens with
    /// neighbours on both sides.
    static let leadingCardCount = 2
    /// How close to the last card a swipe gets before more are dealt.
    static let prefetchDistance = 4

    private(set) var items: [HomeCarouselItem] = []
    private(set) var isLoaded = false

    private var deck = HomeCityDeck(cities: [])

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    /// The card the carousel opens on.
    var initialItemID: HomeCarouselItem.ID? {
        self.items.indices.contains(Self.leadingCardCount)
            ? self.items[Self.leadingCardCount].id
            : self.items.first?.id
    }

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
        self.items = []
        self.dealMore()
        self.isLoaded = !self.items.isEmpty
    }

    /// Deals more cards once a swipe nears the end of the ones already dealt.
    func cardDidAppear(_ item: HomeCarouselItem) {
        guard let lastID = self.items.last?.id, lastID - item.id < Self.prefetchDistance else { return }
        self.dealMore()
    }

    func localTime(for city: CityModel) -> String {
        self.timeFormatter.timeZone = city.timeZone
        return self.timeFormatter.string(from: Date())
    }

    private func dealMore() {
        let nextID = (self.items.last?.id ?? -1) + 1
        let cities = self.deck.deal(Self.batchSize)
        self.items.append(
            contentsOf: cities.enumerated().map { offset, city in
                HomeCarouselItem(id: nextID + offset, city: city)
            }
        )
    }
}
