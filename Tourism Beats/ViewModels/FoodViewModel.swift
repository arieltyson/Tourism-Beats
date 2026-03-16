import SwiftUI

// MARK: - FoodViewModel

/// Manages UI state and filtering logic for the Food Journal tab.
///
/// The actual `@Query` lives on `FoodView`; this view model transforms the
/// raw array into filtered, city-grouped sections and manages sheet state.
@MainActor
@Observable
final class FoodViewModel {
    // MARK: - UI State

    var searchText: String = ""
    var selectedFilter: RestaurantStatus?
    var isAddSheetPresented: Bool = false
    var restaurantToEdit: Restaurant?

    // MARK: - Filtering & Grouping

    /// A city section containing its sorted restaurants.
    struct CitySection: Identifiable {
        let city: String
        let restaurants: [Restaurant]
        var id: String { self.city }
    }

    /// Filters restaurants by search text and status, then groups by city.
    ///
    /// - Cities are sorted alphabetically.
    /// - Restaurants within each city sort by score descending (unrated last).
    func filteredSections(from restaurants: [Restaurant]) -> [CitySection] {
        let filtered = restaurants.filter { restaurant in
            self.matchesFilter(restaurant) && self.matchesSearch(restaurant)
        }

        let grouped = Dictionary(grouping: filtered) { $0.city }

        return grouped
            .sorted { $0.key.localizedCompare($1.key) == .orderedAscending }
            .map { city, items in
                CitySection(
                    city: city,
                    restaurants: items.sorted { lhs, rhs in
                        (lhs.clampedScore ?? -1) > (rhs.clampedScore ?? -1)
                    }
                )
            }
    }

    /// Distinct city names from all restaurants, for auto-suggest in the form.
    func existingCities(from restaurants: [Restaurant]) -> [String] {
        Array(Set(restaurants.map(\.city)))
            .sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    // MARK: - Private

    private func matchesFilter(_ restaurant: Restaurant) -> Bool {
        guard let filter = self.selectedFilter else { return true }
        return restaurant.status == filter
    }

    private func matchesSearch(_ restaurant: Restaurant) -> Bool {
        guard !self.searchText.isEmpty else { return true }
        let query = self.searchText
        return restaurant.name.localizedStandardContains(query)
            || restaurant.city.localizedStandardContains(query)
            || restaurant.country.localizedStandardContains(query)
            || (restaurant.bestDish?.localizedStandardContains(query) ?? false)
    }
}
