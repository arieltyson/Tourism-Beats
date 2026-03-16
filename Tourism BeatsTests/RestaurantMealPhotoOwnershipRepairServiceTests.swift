import Foundation
import SwiftData
import Testing
@testable import Tourism_Beats

@Suite(.serialized)
@MainActor
final class RestaurantMealPhotoOwnershipRepairServiceTests {
    @Test func repairAssignsLegacyMealPhotoToClosestRestaurantAndSeparatesIdentifiers() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext

        let sharedIdentifier = UUID()

        let robin = Restaurant(
            restaurantIdentifier: sharedIdentifier,
            name: "Robin",
            city: "San Francisco",
            country: "United States",
            cuisine: .japanese
        )
        robin.dateAdded = Date(timeIntervalSince1970: 1_000)

        let marutama = Restaurant(
            restaurantIdentifier: sharedIdentifier,
            name: "Marutama Ramen",
            city: "Vancouver",
            country: "Canada",
            cuisine: .japanese
        )
        marutama.dateAdded = Date(timeIntervalSince1970: 2_000)

        let mealPhoto = RestaurantMealPhoto(
            photoIdentifier: UUID(),
            restaurantIdentifier: sharedIdentifier,
            relativePath: "legacy-marutama.jpg",
            dateAdded: Date(timeIntervalSince1970: 2_100)
        )

        modelContext.insert(robin)
        modelContext.insert(marutama)
        modelContext.insert(mealPhoto)
        try modelContext.save()

        try RestaurantMealPhotoOwnershipRepairService().repairIfNeeded(in: modelContext)

        #expect(mealPhoto.restaurant?.name == "Marutama Ramen")
        #expect(marutama.sortedMealPhotos.map(\.relativePath) == ["legacy-marutama.jpg"])
        #expect(robin.sortedMealPhotos.isEmpty)
        #expect(robin.restaurantIdentifier != marutama.restaurantIdentifier)
        #expect(mealPhoto.restaurantIdentifier == marutama.restaurantIdentifier)
    }

    @Test func sortedMealPhotosRemainScopedToTheirRestaurantRelationship() throws {
        let container = try self.makeInMemoryContainer()
        let modelContext = container.mainContext

        let marutama = Restaurant(
            name: "Marutama Ramen",
            city: "Vancouver",
            country: "Canada",
            cuisine: .japanese
        )
        let robin = Restaurant(
            name: "Robin",
            city: "San Francisco",
            country: "United States",
            cuisine: .japanese
        )

        let olderPhoto = RestaurantMealPhoto(
            restaurantIdentifier: marutama.restaurantIdentifier,
            relativePath: "marutama-1.jpg",
            dateAdded: Date(timeIntervalSince1970: 1_000),
            restaurant: marutama
        )
        let newerPhoto = RestaurantMealPhoto(
            restaurantIdentifier: marutama.restaurantIdentifier,
            relativePath: "marutama-2.jpg",
            dateAdded: Date(timeIntervalSince1970: 2_000),
            restaurant: marutama
        )
        let robinPhoto = RestaurantMealPhoto(
            restaurantIdentifier: robin.restaurantIdentifier,
            relativePath: "robin-1.jpg",
            dateAdded: Date(timeIntervalSince1970: 1_500),
            restaurant: robin
        )

        modelContext.insert(marutama)
        modelContext.insert(robin)
        marutama.attachMealPhoto(olderPhoto)
        marutama.attachMealPhoto(newerPhoto)
        robin.attachMealPhoto(robinPhoto)
        modelContext.insert(olderPhoto)
        modelContext.insert(newerPhoto)
        modelContext.insert(robinPhoto)
        try modelContext.save()

        #expect(
            marutama.sortedMealPhotos.map(\.relativePath) ==
                ["marutama-1.jpg", "marutama-2.jpg"]
        )
        #expect(robin.sortedMealPhotos.map(\.relativePath) == ["robin-1.jpg"])
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Restaurant.self,
            RestaurantMealPhoto.self,
            configurations: configuration
        )
    }
}
