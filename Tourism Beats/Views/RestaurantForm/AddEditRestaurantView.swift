import PhotosUI
import SwiftData
import SwiftUI

// MARK: - AddEditRestaurantView

struct AddEditRestaurantView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let restaurant: Restaurant?
    private let restaurantIdentifier: UUID
    let existingCities: [String]

    @State private var name: String
    @State private var city: String
    @State private var country: String
    @State private var cuisine: RestaurantCuisine?
    @State private var hasScore: Bool
    @State private var scoreValue: Int
    @State private var bestDish: String
    @State private var locationURLString: String
    @State private var menuURLString: String
    @State private var status: RestaurantStatus
    @State private var notes: String
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var stagedMealPhotos: [StagedRestaurantMealPhoto] = []
    @State private var removedPhotoIdentifiers: Set<UUID> = []
    @State private var photoImportErrorMessage: String?
    @State private var isImportingMealPhotos: Bool = false
    @State private var hasCommittedChanges: Bool = false
    @State private var isDeleteConfirmationPresented: Bool = false

    private var isEditing: Bool {
        self.restaurant != nil
    }

    private var canSave: Bool {
        !self.trimmedName.isEmpty
            && !self.trimmedCity.isEmpty
            && self.locationURLValidationMessage == nil
            && self.menuURLValidationMessage == nil
    }

    private var existingMealPhotos: [RestaurantMealPhoto] {
        (self.restaurant?.sortedMealPhotos ?? []).filter {
            !self.removedPhotoIdentifiers.contains($0.photoIdentifier)
        }
    }

    init(restaurant: Restaurant? = nil, existingCities: [String] = []) {
        self.restaurant = restaurant
        self.restaurantIdentifier = restaurant?.restaurantIdentifier ?? UUID()
        self.existingCities = existingCities
        self._name = State(initialValue: restaurant?.name ?? "")
        self._city = State(initialValue: restaurant?.city ?? "")
        self._country = State(initialValue: restaurant?.country ?? "")
        self._cuisine = State(initialValue: restaurant?.cuisine)
        self._hasScore = State(initialValue: restaurant?.score != nil)
        self._scoreValue = State(initialValue: restaurant?.clampedScore ?? 7)
        self._bestDish = State(initialValue: restaurant?.bestDish ?? "")
        self._locationURLString = State(initialValue: restaurant?.locationURLString ?? "")
        self._menuURLString = State(initialValue: restaurant?.menuURLString ?? "")
        self._status = State(initialValue: restaurant?.status ?? .wantToTry)
        self._notes = State(initialValue: restaurant?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                RestaurantFormIdentitySection(
                    name: self.$name,
                    city: self.$city,
                    country: self.$country,
                    existingCities: self.existingCities
                )
                RestaurantFormDetailsSection(cuisine: self.$cuisine, bestDish: self.$bestDish)
                RestaurantFormMealPhotosSection(
                    selectedPhotoItems: self.$selectedPhotoItems,
                    isImporting: self.isImportingMealPhotos,
                    errorMessage: self.photoImportErrorMessage,
                    existingMealPhotos: self.existingMealPhotos,
                    stagedMealPhotos: self.stagedMealPhotos,
                    onRemoveExisting: { photo in
                        self.removedPhotoIdentifiers.insert(photo.photoIdentifier)
                    },
                    onRemoveStaged: self.removeStagedMealPhoto
                )
                RestaurantFormRatingSection(hasScore: self.$hasScore, scoreValue: self.$scoreValue)
                RestaurantFormLinksSection(
                    locationURLString: self.$locationURLString,
                    menuURLString: self.$menuURLString,
                    locationValidationMessage: self.locationURLValidationMessage,
                    menuValidationMessage: self.menuURLValidationMessage
                )
                RestaurantFormStatusSection(status: self.$status)
                RestaurantFormNotesSection(notes: self.$notes)

                if self.isEditing {
                    RestaurantFormDangerZoneSection {
                        self.isDeleteConfirmationPresented = true
                    }
                }
            }
            .navigationTitle(self.isEditing ? "Edit Restaurant" : "Add Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(self.isEditing ? "Save" : "Add") {
                        self.save()
                    }
                    .disabled(!self.canSave)
                }
            }
        }
        .interactiveDismissDisabled(self.hasUnsavedChanges)
        .confirmationDialog(
            "Delete this restaurant?",
            isPresented: self.$isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Restaurant", role: .destructive) {
                self.deleteRestaurant()
            }
        } message: {
            Text("This removes the restaurant and any saved meal photos.")
        }
        .onChange(of: self.selectedPhotoItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                await self.importMealPhotos(from: newItems)
            }
        }
        .onDisappear {
            guard !self.hasCommittedChanges, !self.stagedMealPhotos.isEmpty else { return }
            let stagedPaths = self.stagedMealPhotos.map(\.relativePath)
            Task {
                try? await RestaurantMealPhotoStore.shared.deleteFiles(at: stagedPaths)
            }
        }
    }

    private func save() {
        let mealPhotosToDelete = (self.restaurant?.sortedMealPhotos ?? []).filter {
            self.removedPhotoIdentifiers.contains($0.photoIdentifier)
        }

        let targetRestaurant: Restaurant

        if let restaurant = self.restaurant {
            restaurant.name = self.trimmedName
            restaurant.city = self.trimmedCity
            restaurant.country = self.trimmedCountry
            restaurant.cuisine = self.cuisine
            restaurant.score = self.hasScore ? self.scoreValue : nil
            restaurant.bestDish = self.trimmedBestDish.isEmpty ? nil : self.trimmedBestDish
            restaurant.status = self.status
            restaurant.locationURLString = Self.normalizedURLString(from: self.locationURLString)
            restaurant.menuURLString = Self.normalizedURLString(from: self.menuURLString)
            restaurant.notes = self.trimmedNotes.isEmpty ? nil : self.trimmedNotes
            targetRestaurant = restaurant
        } else {
            let restaurant = Restaurant(
                restaurantIdentifier: self.restaurantIdentifier,
                name: self.trimmedName,
                city: self.trimmedCity,
                country: self.trimmedCountry,
                score: self.hasScore ? self.scoreValue : nil,
                cuisine: self.cuisine,
                bestDish: self.trimmedBestDish.isEmpty ? nil : self.trimmedBestDish,
                status: self.status,
                locationURLString: Self.normalizedURLString(from: self.locationURLString),
                menuURLString: Self.normalizedURLString(from: self.menuURLString),
                notes: self.trimmedNotes.isEmpty ? nil : self.trimmedNotes
            )
            self.modelContext.insert(restaurant)
            targetRestaurant = restaurant
        }

        for mealPhoto in mealPhotosToDelete {
            self.modelContext.delete(mealPhoto)
        }

        for stagedMealPhoto in self.stagedMealPhotos {
            let mealPhoto = RestaurantMealPhoto(
                photoIdentifier: stagedMealPhoto.photoIdentifier,
                restaurantIdentifier: targetRestaurant.restaurantIdentifier,
                relativePath: stagedMealPhoto.relativePath,
                restaurant: targetRestaurant
            )
            targetRestaurant.attachMealPhoto(mealPhoto)
            self.modelContext.insert(mealPhoto)
        }

        self.hasCommittedChanges = true
        self.dismiss()

        let deletedPaths = mealPhotosToDelete.map(\.relativePath)
        Task {
            try? await RestaurantMealPhotoStore.shared.deleteFiles(at: deletedPaths)
        }
    }

    private func deleteRestaurant() {
        guard let restaurant = self.restaurant else { return }

        let mealPhotos = restaurant.sortedMealPhotos
        let stagedPaths = self.stagedMealPhotos.map(\.relativePath)

        self.modelContext.delete(restaurant)
        self.hasCommittedChanges = true
        self.dismiss()

        let deletedPaths = mealPhotos.map(\.relativePath) + stagedPaths
        Task {
            try? await RestaurantMealPhotoStore.shared.deleteFiles(at: deletedPaths)
        }
    }

    @MainActor
    private func importMealPhotos(from items: [PhotosPickerItem]) async {
        self.isImportingMealPhotos = true
        self.photoImportErrorMessage = nil

        defer {
            self.isImportingMealPhotos = false
            self.selectedPhotoItems = []
        }

        var failedImportCount = 0

        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    failedImportCount += 1
                    continue
                }

                let photoIdentifier = UUID()
                let relativePath = try await RestaurantMealPhotoStore.shared.persistPhotoData(
                    data,
                    restaurantIdentifier: self.restaurantIdentifier,
                    photoIdentifier: photoIdentifier
                )

                self.stagedMealPhotos.append(
                    StagedRestaurantMealPhoto(
                        photoIdentifier: photoIdentifier,
                        relativePath: relativePath
                    )
                )
            } catch {
                failedImportCount += 1
            }
        }

        if failedImportCount > 0 {
            self.photoImportErrorMessage = failedImportCount == 1
                ? "One photo could not be imported."
                : "\(failedImportCount.formatted(.number)) photos could not be imported."
        }
    }

    private func removeStagedMealPhoto(_ photo: StagedRestaurantMealPhoto) {
        self.stagedMealPhotos.removeAll { $0.photoIdentifier == photo.photoIdentifier }

        Task {
            try? await RestaurantMealPhotoStore.shared.deleteFiles(at: [photo.relativePath])
        }
    }

    private var hasUnsavedChanges: Bool {
        if let restaurant = self.restaurant {
            return self.name != restaurant.name
                || self.city != restaurant.city
                || self.country != restaurant.country
                || self.cuisine != restaurant.cuisine
                || self.hasScore != (restaurant.score != nil)
                || self.scoreValue != (restaurant.clampedScore ?? 7)
                || self.bestDish != (restaurant.bestDish ?? "")
                || self.locationURLString != (restaurant.locationURLString ?? "")
                || self.menuURLString != (restaurant.menuURLString ?? "")
                || self.status != restaurant.status
                || self.notes != (restaurant.notes ?? "")
                || !self.stagedMealPhotos.isEmpty
                || !self.removedPhotoIdentifiers.isEmpty
        }

        return !self.name.isEmpty
            || !self.city.isEmpty
            || !self.country.isEmpty
            || self.cuisine != nil
            || self.hasScore
            || !self.bestDish.isEmpty
            || !self.locationURLString.isEmpty
            || !self.menuURLString.isEmpty
            || self.status != .wantToTry
            || !self.notes.isEmpty
            || !self.stagedMealPhotos.isEmpty
    }

    private var trimmedName: String {
        self.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCity: String {
        self.city.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCountry: String {
        self.country.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBestDish: String {
        self.bestDish.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNotes: String {
        self.notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var locationURLValidationMessage: String? {
        self.validationMessage(for: self.locationURLString, label: "map link")
    }

    private var menuURLValidationMessage: String? {
        self.validationMessage(for: self.menuURLString, label: "menu link")
    }

    private func validationMessage(for value: String, label: String) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }
        guard Self.normalizedURLString(from: value) != nil else {
            return "Enter a valid \(label)."
        }
        return nil
    }

    private static func normalizedURLString(from value: String) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }

        let candidateValue: String = if trimmedValue.contains("://") {
            trimmedValue
        } else {
            "https://\(trimmedValue)"
        }

        guard let components = URLComponents(string: candidateValue),
              let scheme = components.scheme?.lowercased(),
              let url = components.url
        else {
            return nil
        }

        let isWebURL = ["http", "https"].contains(scheme) && components.host != nil
        let isSupportedMapsURL = ["maps", "comgooglemaps"].contains(scheme)

        guard isWebURL || isSupportedMapsURL else {
            return nil
        }

        return url.absoluteString
    }
}
