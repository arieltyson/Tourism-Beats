import SwiftUI

// MARK: - FoodViewModel

/// Manages the Food Journal's top-level filtering, grouping, and sheet state.
@MainActor
@Observable
final class FoodViewModel {
    var searchText: String = ""
    private(set) var selectedFilter: RestaurantStatus?
    /// A ranking shown in place of the journal, so each stays a tap away
    /// once the journal has restaurants.
    private(set) var selectedShowcase: FoodShowcase?
    var isAddSheetPresented: Bool = false
    var restaurantToEdit: Restaurant?

    /// The world's gastronomic capitals, each joined to the catalog city it
    /// opens. A ranked city missing from the catalog is left out.
    let gastroCities: [FeaturedGastroCity]

    private let catalog: FoodCatalog

    /// Uses the bundled catalog unless given another, such as in tests.
    init(catalog: FoodCatalog = .bundled, gastroRanking: [GastroCity] = GastroCityRanking.top) {
        self.catalog = catalog
        self.gastroCities = gastroRanking.compactMap { ranking in
            catalog.city(named: ranking.name, countryCode: ranking.countryCode)
                .map { FeaturedGastroCity(ranking: ranking, city: $0) }
        }
    }

    /// Shows the journal, narrowed to `filter` when there is one.
    func select(_ filter: RestaurantStatus?) {
        self.selectedFilter = filter
        self.selectedShowcase = nil
    }

    /// Shows `showcase` in place of the journal.
    func select(_ showcase: FoodShowcase) {
        self.selectedShowcase = showcase
    }

    /// Whether the journal is showing anything other than all of it.
    var isNarrowed: Bool {
        self.selectedFilter != nil || self.selectedShowcase != nil
    }

    /// The ranking to show now. Searching always searches the journal itself.
    var visibleShowcase: FoodShowcase? {
        self.searchText.isEmpty ? self.selectedShowcase : nil
    }

    func cityGroups(from restaurants: [Restaurant]) -> [FoodJournalCityGroup] {
        let visibleKeys = Set(
            restaurants
                .filter { self.matchesFilter($0) && self.matchesSearch($0) }
                .map { self.groupKey(for: $0) }
        )

        let groupedRestaurants = Dictionary(
            grouping: restaurants,
            by: { self.groupKey(for: $0) }
        )

        return groupedRestaurants
            .compactMap { key, items in
                guard visibleKeys.contains(key) else { return nil }
                return self.makeCityGroup(from: items, key: key)
            }
            .sorted {
                $0.displayCityName.localizedCompare($1.displayCityName) == .orderedAscending
            }
    }

    /// The cities and countries the restaurant form offers, with the journal's
    /// own places first in the order the restaurants are given.
    ///
    /// A journal place that is a catalog city replaces that city in the
    /// catalog list, so choosing it again keeps the journal's spelling (for
    /// example "United States" rather than "United States of America") and the
    /// restaurant joins the same city group.
    func placeOptions(from restaurants: [Restaurant]) -> RestaurantPlaceOptions {
        var seenIdentifiers = Set<String>()
        var coveredCatalogCityIdentifiers = Set<String>()

        let journalPlaces: [RestaurantPlace] = restaurants.compactMap { restaurant in
            let city = restaurant.city.trimmingCharacters(in: .whitespacesAndNewlines)
            let country = restaurant.country.trimmingCharacters(in: .whitespacesAndNewlines)
            let place = RestaurantPlace(city: city, country: country)
            guard !city.isEmpty, seenIdentifiers.insert(place.id).inserted else { return nil }

            let catalogCity = self.resolveCity(cityName: city, countryName: country)
            if let catalogCity {
                coveredCatalogCityIdentifiers.insert(
                    RestaurantPlace(city: catalogCity.name, country: catalogCity.country.name).id
                )
            }

            return RestaurantPlace(
                city: city,
                country: country,
                flag: catalogCity?.country.flag
                    ?? self.catalog.flagsByNormalizedCountryName[FoodJournalCityGroup.normalizedLookupValue(country)],
                searchAliases: catalogCity?.alternateSearchNames ?? []
            )
        }

        return RestaurantPlaceOptions(
            journalPlaces: journalPlaces,
            catalogPlaces: self.catalog.places.filter { !coveredCatalogCityIdentifiers.contains($0.id) },
            countries: self.catalog.countries
        )
    }

    private func groupKey(for restaurant: Restaurant) -> String {
        FoodJournalCityGroup.groupKey(
            city: restaurant.city,
            country: restaurant.country
        )
    }

    private func makeCityGroup(
        from restaurants: [Restaurant],
        key: String
    ) -> FoodJournalCityGroup {
        let representative = self.representativeRestaurant(from: restaurants)
        let rawCityName = representative?.city.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawCountryName = representative?.country.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return FoodJournalCityGroup(
            key: key,
            rawCityName: rawCityName,
            rawCountryName: rawCountryName,
            restaurantCount: restaurants.count,
            city: self.resolveCity(cityName: rawCityName, countryName: rawCountryName)
        )
    }

    private func representativeRestaurant(
        from restaurants: [Restaurant]
    ) -> Restaurant? {
        restaurants.min { lhs, rhs in
            let lhsDisplay = "\(lhs.city) \(lhs.country)"
            let rhsDisplay = "\(rhs.city) \(rhs.country)"
            return lhsDisplay.localizedCompare(rhsDisplay) == .orderedAscending
        }
    }

    private func resolveCity(cityName: String, countryName: String) -> CityModel? {
        let normalizedCityName = FoodJournalCityGroup.normalizedLookupValue(cityName)
        guard !normalizedCityName.isEmpty else { return nil }

        let candidates = self.catalog.citiesByNormalizedName[normalizedCityName] ?? []
        guard !candidates.isEmpty else { return nil }

        let normalizedCountryName = FoodJournalCityGroup.normalizedLookupValue(countryName)
        if !normalizedCountryName.isEmpty {
            if let exactMatch = candidates.first(where: {
                self.countryTokens(for: $0).contains(normalizedCountryName)
            }) {
                return exactMatch
            }

            if let partialMatch = candidates.first(where: { city in
                self.countryTokens(for: city).contains { token in
                    token.localizedStandardContains(normalizedCountryName)
                        || normalizedCountryName.localizedStandardContains(token)
                }
            }) {
                return partialMatch
            }
        }

        return candidates.count == 1 ? candidates.first : nil
    }

    private func countryTokens(for city: CityModel) -> Set<String> {
        var tokens = Set(
            [
                FoodJournalCityGroup.normalizedLookupValue(city.country.name),
                FoodJournalCityGroup.normalizedLookupValue(city.country.code)
            ]
        )

        switch city.country.code {
        case "US":
            tokens.formUnion(["united states", "united states of america", "usa", "us"])
        case "GB":
            tokens.formUnion(["united kingdom", "uk", "great britain"])
        case "AE":
            tokens.formUnion(["united arab emirates", "uae"])
        default:
            break
        }

        return Set(tokens.filter { !$0.isEmpty })
    }

    private func matchesFilter(_ restaurant: Restaurant) -> Bool {
        guard let selectedFilter else { return true }
        return restaurant.status == selectedFilter
    }

    private func matchesSearch(_ restaurant: Restaurant) -> Bool {
        guard !self.searchText.isEmpty else { return true }

        return restaurant.name.localizedStandardContains(self.searchText)
            || restaurant.city.localizedStandardContains(self.searchText)
            || restaurant.country.localizedStandardContains(self.searchText)
            || restaurant.displayCuisine.label.localizedStandardContains(self.searchText)
            || (restaurant.bestDish?.localizedStandardContains(self.searchText) ?? false)
            || (restaurant.notes?.localizedStandardContains(self.searchText) ?? false)
    }
}
