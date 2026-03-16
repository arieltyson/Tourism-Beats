import SwiftUI

// MARK: - FoodViewModel

/// Manages the Food Journal's top-level filtering, grouping, and sheet state.
@MainActor
@Observable
final class FoodViewModel {
    var searchText: String = ""
    var selectedFilter: RestaurantStatus?
    var isAddSheetPresented: Bool = false
    var restaurantToEdit: Restaurant?

    private let catalogCitiesByNormalizedName: [String: [CityModel]]
    private let catalogCityNames: [String]

    init(dataService: DataService = DataService()) {
        let catalogCities = (try? dataService.loadCities()) ?? []
        self.catalogCitiesByNormalizedName = Dictionary(
            grouping: catalogCities,
            by: { FoodJournalCityGroup.normalizedLookupValue($0.name) }
        )
        self.catalogCityNames = catalogCities.map(\.name)
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

    func existingCities(from restaurants: [Restaurant]) -> [String] {
        let restaurantCities = restaurants
            .map(\.city)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Array(Set(restaurantCities + self.catalogCityNames))
            .sorted { $0.localizedCompare($1) == .orderedAscending }
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

        let candidates = self.catalogCitiesByNormalizedName[normalizedCityName] ?? []
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
            || (restaurant.bestDish?.localizedStandardContains(self.searchText) ?? false)
            || (restaurant.notes?.localizedStandardContains(self.searchText) ?? false)
    }
}
