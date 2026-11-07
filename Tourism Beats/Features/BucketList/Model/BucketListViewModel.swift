import Foundation
import OSLog
import SwiftData

// MARK: - BucketListViewModel

/// Adds, completes, and removes bucket list items.
///
/// The list itself is read live by each screen; this model owns the rules
/// for changing it: activities need words, and a place is on the list once.
@MainActor
@Observable
final class BucketListViewModel {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "BucketList"
    )

    @ObservationIgnored private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Adding

    /// Adds an activity, unless it's only whitespace.
    @discardableResult
    func addActivity(_ text: String) -> BucketListItem? {
        let title = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        let item = BucketListItem(activity: title)
        self.modelContext.insert(item)
        self.save()
        return item
    }

    /// Adds a country, or a city in it. A place already on the list is
    /// returned as it is rather than added twice.
    @discardableResult
    func addPlace(country: CountryModel, city: CityModel? = nil) -> BucketListItem {
        if let existing = self.item(country: country, city: city) {
            return existing
        }
        let item = BucketListItem(country: country, city: city)
        self.modelContext.insert(item)
        self.save()
        return item
    }

    // MARK: - Cities

    /// Whether a city is on the list.
    func contains(city: CityModel) -> Bool {
        self.item(country: city.country, city: city) != nil
    }

    /// Adds a city that isn't on the list, or removes one that is, and says
    /// which it did.
    func toggle(city: CityModel) -> BucketListConfirmation {
        if let existing = self.item(country: city.country, city: city) {
            self.delete(existing)
            return BucketListConfirmation(placeName: city.name, wasAdded: false)
        }
        self.addPlace(country: city.country, city: city)
        return BucketListConfirmation(placeName: city.name, wasAdded: true)
    }

    // MARK: - Changing

    func toggleCompletion(of item: BucketListItem) {
        item.isCompleted.toggle()
        self.save()
    }

    func delete(_ item: BucketListItem) {
        self.modelContext.delete(item)
        self.save()
    }

    // MARK: - Sections

    /// The places, oldest first, so the list reads in the order it was made.
    static func places(in items: [BucketListItem]) -> [BucketListItem] {
        items.filter { $0.kind == .place }.sorted { $0.dateAdded < $1.dateAdded }
    }

    /// The activities, oldest first.
    static func activities(in items: [BucketListItem]) -> [BucketListItem] {
        items.filter { $0.kind == .activity }.sorted { $0.dateAdded < $1.dateAdded }
    }

    // MARK: - Private

    /// The list's entry for a country alone, or for a city in it.
    private func item(country: CountryModel, city: CityModel?) -> BucketListItem? {
        let placeKind = BucketListItemKind.place.rawValue
        let descriptor = FetchDescriptor<BucketListItem>(
            predicate: #Predicate { $0.kindRaw == placeKind }
        )
        let places = (try? self.modelContext.fetch(descriptor)) ?? []
        return places.first { place in
            if let city {
                return place.cityID == city.id
            }
            return place.cityID == nil && place.countryCode == country.code
        }
    }

    private func save() {
        do {
            try self.modelContext.save()
        } catch {
            Self.logger.error("Bucket list save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
