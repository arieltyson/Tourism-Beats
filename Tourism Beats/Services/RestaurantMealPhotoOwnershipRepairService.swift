import Foundation
import OSLog
import SwiftData

// MARK: - RestaurantMealPhotoOwnershipRepairService

/// Repairs legacy meal photo ownership after the app moved from a manual UUID
/// foreign key to a first-class SwiftData relationship.
///
/// The repair is intentionally idempotent so it can run at launch without
/// needing a separate migration flag.
@MainActor
struct RestaurantMealPhotoOwnershipRepairService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "RestaurantMealPhotoOwnershipRepair"
    )

    func repairIfNeeded(in modelContext: ModelContext) throws {
        let restaurants = try modelContext.fetch(FetchDescriptor<Restaurant>())
        let mealPhotos = try modelContext.fetch(FetchDescriptor<RestaurantMealPhoto>())

        guard !restaurants.isEmpty || !mealPhotos.isEmpty else { return }

        let legacyIdentifierGroups = Dictionary(
            grouping: restaurants,
            by: \.restaurantIdentifier
        )
        let sortedMealPhotos = mealPhotos.sorted(by: self.photoSortOrder)

        var repairedOwnershipCount = 0
        var synchronizedLegacyIdentifierCount = 0
        var reassignedRestaurantIdentifierCount = 0
        var linkedPhotoCountsByRestaurant = [ObjectIdentifier: Int]()

        for mealPhoto in sortedMealPhotos {
            if let restaurant = mealPhoto.restaurant {
                linkedPhotoCountsByRestaurant[ObjectIdentifier(restaurant), default: 0] += 1
                continue
            }

            let candidates = legacyIdentifierGroups[mealPhoto.restaurantIdentifier] ?? []
            guard
                let owner = self.resolveOwner(
                    for: mealPhoto,
                    candidates: candidates,
                    linkedPhotoCountsByRestaurant: linkedPhotoCountsByRestaurant
                )
            else {
                continue
            }

            owner.attachMealPhoto(mealPhoto)
            linkedPhotoCountsByRestaurant[ObjectIdentifier(owner), default: 0] += 1
            repairedOwnershipCount += 1
        }

        for restaurantsWithSharedLegacyIdentifier in legacyIdentifierGroups.values {
            let orderedRestaurants = self.restaurantsOrderedForLegacyIdentifierRepair(
                restaurantsWithSharedLegacyIdentifier,
                linkedPhotoCountsByRestaurant: linkedPhotoCountsByRestaurant
            )
            guard let canonicalRestaurant = orderedRestaurants.first else { continue }

            for duplicateRestaurant in orderedRestaurants.dropFirst() {
                guard
                    duplicateRestaurant.restaurantIdentifier == canonicalRestaurant.restaurantIdentifier
                else {
                    continue
                }

                duplicateRestaurant.restaurantIdentifier = UUID()
                reassignedRestaurantIdentifierCount += 1
            }
        }

        for mealPhoto in sortedMealPhotos {
            guard
                let restaurant = mealPhoto.restaurant,
                mealPhoto.restaurantIdentifier != restaurant.restaurantIdentifier
            else {
                continue
            }

            mealPhoto.restaurantIdentifier = restaurant.restaurantIdentifier
            synchronizedLegacyIdentifierCount += 1
        }

        guard modelContext.hasChanges else { return }

        try modelContext.save()
        self.logger.notice(
            """
            Repaired \(repairedOwnershipCount, privacy: .public) meal photo ownership records, \
            synchronized \(synchronizedLegacyIdentifierCount, privacy: .public) legacy identifiers, \
            and reassigned \(reassignedRestaurantIdentifierCount, privacy: .public) duplicate restaurant identifiers.
            """
        )
    }

    private func resolveOwner(
        for mealPhoto: RestaurantMealPhoto,
        candidates: [Restaurant],
        linkedPhotoCountsByRestaurant: [ObjectIdentifier: Int]
    ) -> Restaurant? {
        guard !candidates.isEmpty else { return nil }

        let availableCandidates = candidates.filter { $0.dateAdded <= mealPhoto.dateAdded }
        let candidatePool = availableCandidates.isEmpty ? candidates : availableCandidates

        return candidatePool.min { lhs, rhs in
            let lhsLinkedPhotoCount = linkedPhotoCountsByRestaurant[ObjectIdentifier(lhs), default: 0]
            let rhsLinkedPhotoCount = linkedPhotoCountsByRestaurant[ObjectIdentifier(rhs), default: 0]
            if lhsLinkedPhotoCount != rhsLinkedPhotoCount {
                return lhsLinkedPhotoCount > rhsLinkedPhotoCount
            }

            let lhsDistance = abs(lhs.dateAdded.timeIntervalSince(mealPhoto.dateAdded))
            let rhsDistance = abs(rhs.dateAdded.timeIntervalSince(mealPhoto.dateAdded))
            if lhsDistance != rhsDistance {
                return lhsDistance < rhsDistance
            }

            if lhs.dateAdded != rhs.dateAdded {
                return lhs.dateAdded > rhs.dateAdded
            }

            return self.restaurantRepairSortKey(lhs) < self.restaurantRepairSortKey(rhs)
        }
    }

    private func restaurantsOrderedForLegacyIdentifierRepair(
        _ restaurants: [Restaurant],
        linkedPhotoCountsByRestaurant: [ObjectIdentifier: Int]
    ) -> [Restaurant] {
        restaurants.sorted { lhs, rhs in
            let lhsLinkedPhotoCount = linkedPhotoCountsByRestaurant[ObjectIdentifier(lhs), default: 0]
            let rhsLinkedPhotoCount = linkedPhotoCountsByRestaurant[ObjectIdentifier(rhs), default: 0]
            if lhsLinkedPhotoCount != rhsLinkedPhotoCount {
                return lhsLinkedPhotoCount > rhsLinkedPhotoCount
            }

            if lhs.dateAdded != rhs.dateAdded {
                return lhs.dateAdded < rhs.dateAdded
            }

            return self.restaurantRepairSortKey(lhs) < self.restaurantRepairSortKey(rhs)
        }
    }

    private func photoSortOrder(
        _ lhs: RestaurantMealPhoto,
        _ rhs: RestaurantMealPhoto
    ) -> Bool {
        if lhs.dateAdded != rhs.dateAdded {
            return lhs.dateAdded < rhs.dateAdded
        }
        return lhs.photoIdentifier.uuidString < rhs.photoIdentifier.uuidString
    }

    private func restaurantRepairSortKey(_ restaurant: Restaurant) -> String {
        [
            restaurant.name,
            restaurant.city,
            restaurant.country,
            restaurant.restaurantIdentifier.uuidString
        ]
        .joined(separator: "|")
        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
