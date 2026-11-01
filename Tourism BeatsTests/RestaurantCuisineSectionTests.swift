import Testing
@testable import Tourism_Beats

// MARK: - RestaurantCuisineSectionTests

struct RestaurantCuisineSectionTests {
    @Test func emptySearchListsEveryCuisineOnceWithDrinksFirst() {
        let sections = RestaurantCuisineSection.sections(matching: "")
        let listed = sections.flatMap(\.cuisines)

        #expect(sections.first?.category == .drinks)
        #expect(listed.count == RestaurantCuisine.allCases.count)
        #expect(Set(listed) == Set(RestaurantCuisine.allCases))
    }

    @Test func cuisinesAreAlphabeticalWithinASection() {
        for section in RestaurantCuisineSection.sections(matching: "") {
            let labels = section.cuisines.map(\.label)
            #expect(labels == labels.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        }
    }

    @Test(arguments: [
        ("matcha", RestaurantCuisine.tea),
        ("Boba", .bubbleTea),
        ("smoothie", .juice),
        ("latte", .coffee),
        ("ital", .italian),
    ])
    func searchFindsCuisinesByLabelOrKeyword(query: String, expected: RestaurantCuisine) {
        let results = RestaurantCuisineSection.sections(matching: query).flatMap(\.cuisines)

        #expect(results.contains(expected))
    }

    @Test func searchingAGroupNameListsTheWholeGroup() {
        let sections = RestaurantCuisineSection.sections(matching: "drinks")

        #expect(sections.map(\.category) == [.drinks])
    }

    @Test func searchWithNoMatchesReturnsNoSections() {
        #expect(RestaurantCuisineSection.sections(matching: "zzzz").isEmpty)
    }
}
