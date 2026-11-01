import Foundation

// MARK: - RestaurantCuisineSection

/// One group of cuisines in the cuisine list, such as Drinks.
struct RestaurantCuisineSection: Identifiable, Equatable, Sendable {
    let category: RestaurantCuisineCategory
    let cuisines: [RestaurantCuisine]

    var id: RestaurantCuisineCategory { self.category }

    /// The cuisine list for a search, grouped and alphabetized.
    ///
    /// A cuisine matches when the query appears in its label, in one of its
    /// search keywords ("Boba" finds Bubble Tea), or in its group's title
    /// ("Drinks" lists every drink). Empty groups are left out.
    static func sections(matching query: String) -> [RestaurantCuisineSection] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        return RestaurantCuisineCategory.allCases.compactMap { category in
            let cuisines = RestaurantCuisine.allCases
                .filter { $0.category == category }
                .filter { trimmedQuery.isEmpty || $0.matches(trimmedQuery) }
                .sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending }

            guard !cuisines.isEmpty else { return nil }
            return RestaurantCuisineSection(category: category, cuisines: cuisines)
        }
    }
}

// MARK: - Matching

private extension RestaurantCuisine {
    func matches(_ query: String) -> Bool {
        ([self.label, self.category.title] + self.searchKeywords)
            .contains { $0.localizedStandardContains(query) }
    }
}
