import Testing
@testable import Tourism_Beats

@MainActor
struct TripsViewModelPresentationTests {
    @Test func filteredSectionsHideSampleTripsWhenUserTripsExist() {
        let viewModel = TripsViewModel(catalogCities: [], countries: [])
        let sampleTrip = Trip(
            name: "Vancouver, BC",
            city: "Vancouver",
            country: "Canada",
            isSample: true,
            status: .upcoming
        )
        let userTrip = Trip(
            name: "Summer 2026",
            city: "San Francisco",
            country: "United States of America",
            status: .upcoming
        )

        let sections = viewModel.filteredSections(from: [sampleTrip, userTrip])

        #expect(sections.count == 1)
        #expect(sections.first?.trips.count == 1)
        #expect(sections.first?.trips.first?.name == "Summer 2026")
    }
}
