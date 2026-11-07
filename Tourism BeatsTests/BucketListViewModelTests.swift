import Foundation
import SwiftData
import Testing
@testable import Tourism_Beats

// MARK: - BucketListViewModelTests

@Suite(.serialized)
@MainActor
struct BucketListViewModelTests {
    private static let japan = CountryModel(name: "Japan", code: "JP", flag: "🇯🇵")

    private static let kyoto = CityModel(
        id: "Kyoto-JP",
        name: "Kyoto",
        country: japan,
        imageURL: URL(filePath: "/kyoto.jpg"),
        coordinate: .init(latitude: 35.0116, longitude: 135.7681),
        timeZoneIdentifier: "Asia/Tokyo"
    )

    @Test func activitiesAreTrimmedAndNeedWords() throws {
        let (viewModel, context, container) = try Self.makeViewModel()
        defer { withExtendedLifetime(container) {} }

        #expect(viewModel.addActivity("   ") == nil)
        let item = try #require(viewModel.addActivity("  Hot air balloon \n"))

        #expect(item.title == "Hot air balloon")
        #expect(item.kind == .activity)
        #expect(try context.fetchCount(FetchDescriptor<BucketListItem>()) == 1)
    }

    @Test func aPlaceIsOnTheListOnce() throws {
        let (viewModel, context, container) = try Self.makeViewModel()
        defer { withExtendedLifetime(container) {} }

        let first = viewModel.addPlace(country: Self.japan, city: Self.kyoto)
        let second = viewModel.addPlace(country: Self.japan, city: Self.kyoto)

        #expect(first === second)
        #expect(try context.fetchCount(FetchDescriptor<BucketListItem>()) == 1)
    }

    /// A country alone and a city in it are different places to go.
    @Test func aCountryAndOneOfItsCitiesAreSeparatePlaces() throws {
        let (viewModel, context, container) = try Self.makeViewModel()
        defer { withExtendedLifetime(container) {} }

        let country = viewModel.addPlace(country: Self.japan)
        let city = viewModel.addPlace(country: Self.japan, city: Self.kyoto)

        #expect(country.title == "Japan")
        #expect(country.placeDetail == nil)
        #expect(city.title == "Kyoto")
        #expect(city.placeDetail == "Japan")
        #expect(try context.fetchCount(FetchDescriptor<BucketListItem>()) == 2)
    }

    @Test func togglingACityAddsThenRemovesIt() throws {
        let (viewModel, _, container) = try Self.makeViewModel()
        defer { withExtendedLifetime(container) {} }

        let added = viewModel.toggle(city: Self.kyoto)
        #expect(added.wasAdded)
        #expect(added.message == "Kyoto added to Bucket List")
        #expect(viewModel.contains(city: Self.kyoto))

        let removed = viewModel.toggle(city: Self.kyoto)
        #expect(!removed.wasAdded)
        #expect(removed.message == "Kyoto removed from Bucket List")
        #expect(!viewModel.contains(city: Self.kyoto))
    }

    @Test func completingAnItemChecksItOff() throws {
        let (viewModel, _, container) = try Self.makeViewModel()
        defer { withExtendedLifetime(container) {} }
        let item = try #require(viewModel.addActivity("Skydiving"))

        viewModel.toggleCompletion(of: item)
        #expect(item.isCompleted)

        viewModel.toggleCompletion(of: item)
        #expect(!item.isCompleted)
    }

    @Test func sectionsSplitPlacesFromActivitiesInTheOrderAdded() throws {
        let (viewModel, context, container) = try Self.makeViewModel()
        defer { withExtendedLifetime(container) {} }
        viewModel.addActivity("Surfing")
        viewModel.addPlace(country: Self.japan)
        viewModel.addActivity("Dogsledding")

        let items = try context.fetch(FetchDescriptor<BucketListItem>())

        #expect(BucketListViewModel.places(in: items).map(\.title) == ["Japan"])
        #expect(BucketListViewModel.activities(in: items).map(\.title) == ["Surfing", "Dogsledding"])
    }

    /// The container must outlive the test, or its context goes with it.
    private static func makeViewModel() throws -> (BucketListViewModel, ModelContext, ModelContainer) {
        let container = try ModelContainer(
            for: BucketListItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        return (BucketListViewModel(modelContext: context), context, container)
    }
}
