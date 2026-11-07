import SwiftData
import SwiftUI

// MARK: - CityBucketListButton

/// Adds a city to the bucket list, or, once it's there, takes it off.
///
/// A plus while the city isn't on the list, a checkmark while it is, the
/// one turning into the other as the city is added or removed.
struct CityBucketListButton: View {
    let city: CityModel
    let onToggle: (BucketListConfirmation) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Read live, so removing the city from the list's own screen shows here.
    @Query(filter: #Predicate<BucketListItem> { $0.cityID != nil }) private var cities: [BucketListItem]

    var body: some View {
        let isSaved = self.cities.contains { $0.cityID == self.city.id }

        Button(
            isSaved ? "Remove from Bucket List" : "Add to Bucket List",
            systemImage: isSaved ? "checkmark" : "plus"
        ) {
            self.onToggle(BucketListViewModel(modelContext: self.modelContext).toggle(city: self.city))
        }
        .contentTransition(.symbolEffect(.replace))
        .animation(self.reduceMotion ? nil : AnimationTokens.snappy, value: isSaved)
        .accessibilityValue(isSaved ? "On your bucket list" : "")
        .accessibilityInputLabels(
            isSaved
                ? ["Remove from Bucket List", "Remove"]
                : ["Add to Bucket List", "Bucket List", "Save"]
        )
    }
}
