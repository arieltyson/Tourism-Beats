import SwiftData
import Testing
@testable import Tourism_Beats

@Suite(.serialized)
@MainActor
struct TripFormAndDeletionTests {
    @Test func tripFormViewModelSynchronizesMultiwordCountrySelection() {
        let country = CountryModel(
            name: "Trinidad and Tobago",
            code: "TT",
            flag: "🇹🇹"
        )

        let viewModel = TripFormViewModel(
            countries: [country],
            cities: []
        )

        viewModel.synchronizeCountrySelection(with: "Trinidad and Tobago")

        #expect(viewModel.selectedCountryCode == "TT")
        #expect(viewModel.selectedCountryName == "Trinidad and Tobago")
        #expect(viewModel.selectedCountryDisplayLabel == "🇹🇹 Trinidad and Tobago")
    }

    @Test func deletingTripCascadesToDaysAndActivities() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext

        let trip = Trip(
            name: "Trinidad and Tobago",
            city: "Port of Spain",
            country: "Trinidad and Tobago"
        )
        modelContext.insert(trip)

        let day = TripDay(dayNumber: 1, trip: trip)
        modelContext.insert(day)

        let activity = TripActivity(
            name: "Dinner",
            day: day
        )
        modelContext.insert(activity)

        try modelContext.save()

        modelContext.delete(trip)
        try modelContext.save()

        let trips = try modelContext.fetch(FetchDescriptor<Trip>())
        let days = try modelContext.fetch(FetchDescriptor<TripDay>())
        let activities = try modelContext.fetch(FetchDescriptor<TripActivity>())

        #expect(trips.isEmpty)
        #expect(days.isEmpty)
        #expect(activities.isEmpty)
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        return try ModelContainer(
            for: Trip.self,
            TripDay.self,
            TripActivity.self,
            configurations: configuration
        )
    }
}
