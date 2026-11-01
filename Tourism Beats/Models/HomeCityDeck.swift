import Foundation

// MARK: - HomeCityDeck

/// Deals featured cities like a shuffled deck: every city appears once before
/// any repeats, and a fresh shuffle never starts with the city just shown.
struct HomeCityDeck {
    private let cities: [CityModel]
    private var remaining: [CityModel] = []
    private var lastDealt: CityModel?

    init(cities: [CityModel]) {
        self.cities = cities
    }

    var cityCount: Int { self.cities.count }

    /// The next `count` cities, reshuffling whenever the deck runs out.
    mutating func deal(_ count: Int) -> [CityModel] {
        var generator = SystemRandomNumberGenerator()
        return self.deal(count, using: &generator)
    }

    mutating func deal<Generator: RandomNumberGenerator>(
        _ count: Int,
        using generator: inout Generator
    ) -> [CityModel] {
        guard !self.cities.isEmpty, count > 0 else { return [] }

        var dealt: [CityModel] = []
        dealt.reserveCapacity(count)

        while dealt.count < count {
            if self.remaining.isEmpty {
                self.remaining = self.cities.shuffled(using: &generator)
                // Cards are dealt from the end, so keep the last city shown
                // from coming straight back at the start of the new shuffle.
                if self.remaining.count > 1, self.remaining.last == self.lastDealt {
                    self.remaining.swapAt(0, self.remaining.count - 1)
                }
            }

            let city = self.remaining.removeLast()
            dealt.append(city)
            self.lastDealt = city
        }

        return dealt
    }
}
