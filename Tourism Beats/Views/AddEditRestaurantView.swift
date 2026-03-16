import PhotosUI
import SwiftData
import SwiftUI

// MARK: - AddEditRestaurantView

struct AddEditRestaurantView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \RestaurantMealPhoto.dateAdded, order: .forward)
    private var allMealPhotos: [RestaurantMealPhoto]

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
    @State private var showCitySuggestions: Bool = false
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
        self.allMealPhotos.filter {
            $0.restaurantIdentifier == self.restaurantIdentifier
                && !self.removedPhotoIdentifiers.contains($0.photoIdentifier)
        }
    }

    private var totalMealPhotoCount: Int {
        self.existingMealPhotos.count + self.stagedMealPhotos.count
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
                self.restaurantSection
                self.detailsSection
                self.mealPhotosSection
                self.ratingSection
                self.linksSection
                self.statusSection
                self.notesSection

                if self.isEditing {
                    self.dangerZoneSection
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

    private var restaurantSection: some View {
        Section("Restaurant") {
            TextField("Restaurant Name", text: self.$name)
                .textContentType(.organizationName)
                .autocorrectionDisabled()

            VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                TextField("City", text: self.$city)
                    .textContentType(.addressCity)
                    .autocorrectionDisabled()
                    .onChange(of: self.city) { _, newValue in
                        let normalizedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.showCitySuggestions = !normalizedValue.isEmpty
                            && !self.matchingCities.isEmpty
                            && !self.matchingCities.contains(where: {
                                $0.caseInsensitiveCompare(normalizedValue) == .orderedSame
                            })
                    }

                if self.showCitySuggestions {
                    self.citySuggestions
                }
            }

            TextField("Country", text: self.$country)
                .textContentType(.countryName)
                .autocorrectionDisabled()
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            Picker("Cuisine", selection: self.$cuisine) {
                Text("None")
                    .tag(nil as RestaurantCuisine?)

                ForEach(RestaurantCuisine.allCases) { cuisine in
                    Text(cuisine.label)
                        .tag(cuisine as RestaurantCuisine?)
                }
            }

            TextField("Best Dish (optional)", text: self.$bestDish)
        }
    }

    private var mealPhotosSection: some View {
        Section {
            PhotosPicker(
                selection: self.$selectedPhotoItems,
                maxSelectionCount: 6,
                matching: .images
            ) {
                Label("Add Meal Photos", systemImage: "photo.on.rectangle.angled")
                    .font(TypographyTokens.cardLabel)
                    .foregroundStyle(AppColors.coral)
            }
            .disabled(self.isImportingMealPhotos)

            if self.isImportingMealPhotos {
                HStack(spacing: SpacingTokens.small) {
                    ProgressView()
                    Text("Importing photos…")
                        .font(TypographyTokens.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let photoImportErrorMessage {
                Text(photoImportErrorMessage)
                    .font(TypographyTokens.footnote)
                    .foregroundStyle(AppColors.danger)
            }

            if self.totalMealPhotoCount == 0 {
                Text("Add photos from your camera roll to remember what you ordered.")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: SpacingTokens.small) {
                        ForEach(self.existingMealPhotos, id: \.photoIdentifier) { photo in
                            EditableMealPhotoThumbnail(
                                fileURL: RestaurantMealPhotoStore.fileURL(for: photo.relativePath)
                            ) {
                                self.removedPhotoIdentifiers.insert(photo.photoIdentifier)
                            }
                        }

                        ForEach(self.stagedMealPhotos) { photo in
                            EditableMealPhotoThumbnail(
                                fileURL: RestaurantMealPhotoStore.fileURL(for: photo.relativePath)
                            ) {
                                self.removeStagedMealPhoto(photo)
                            }
                        }
                    }
                    .padding(.vertical, SpacingTokens.xxSmall)
                }
                .scrollIndicators(.hidden)
            }
        } header: {
            Text("Meal Photos")
        } footer: {
            Text("Photos are optimized and stored locally to keep the journal fast and space-efficient.")
        }
    }

    private var ratingSection: some View {
        Section("Rating") {
            Toggle("Rate this restaurant", isOn: self.$hasScore.animation(AnimationTokens.standard))
                .tint(AppColors.coral)

            if self.hasScore {
                VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                    HStack {
                        Text("Score")
                            .font(TypographyTokens.body)

                        Spacer()

                        Text("\(self.scoreValue, format: .number)/10")
                            .font(TypographyTokens.songTitle.monospacedDigit())
                            .bold()
                            .foregroundStyle(AppColors.gold)
                    }

                    HStack(spacing: SpacingTokens.xxSmall) {
                        ForEach(1 ... 10, id: \.self) { index in
                            Button {
                                withAnimation(AnimationTokens.press) {
                                    self.scoreValue = index
                                }
                            } label: {
                                Circle()
                                    .fill(
                                        index <= self.scoreValue
                                            ? AnyShapeStyle(AppColors.gold)
                                            : AnyShapeStyle(.quaternary)
                                    )
                                    .frame(width: 22, height: 22)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(index, format: .number)")
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Score: \(self.scoreValue) out of 10")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment:
                            self.scoreValue = min(self.scoreValue + 1, 10)
                        case .decrement:
                            self.scoreValue = max(self.scoreValue - 1, 0)
                        @unknown default:
                            break
                        }
                    }
                }
            }
        }
    }

    private var linksSection: some View {
        Section {
            TextField("Apple Maps or Google Maps link", text: self.$locationURLString)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .textContentType(.URL)
                .autocorrectionDisabled()

            if let locationURLValidationMessage {
                Text(locationURLValidationMessage)
                    .font(TypographyTokens.footnote)
                    .foregroundStyle(AppColors.danger)
            }

            TextField("Menu link", text: self.$menuURLString)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .textContentType(.URL)
                .autocorrectionDisabled()

            if let menuURLValidationMessage {
                Text(menuURLValidationMessage)
                    .font(TypographyTokens.footnote)
                    .foregroundStyle(AppColors.danger)
            }
        } header: {
            Text("Links")
        } footer: {
            Text("Paste full links, or just the site address, and the app will normalize them.")
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: self.$status) {
                ForEach(RestaurantStatus.allCases) { restaurantStatus in
                    Label(restaurantStatus.label, systemImage: restaurantStatus.systemImage)
                        .tag(restaurantStatus)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Add notes (optional)", text: self.$notes, axis: .vertical)
                .lineLimit(3 ... 8)
        }
    }

    private var dangerZoneSection: some View {
        Section {
            Button("Delete Restaurant", role: .destructive) {
                self.isDeleteConfirmationPresented = true
            }
        } header: {
            Text("Danger Zone")
        }
    }

    private var matchingCities: [String] {
        self.existingCities.filter { $0.localizedStandardContains(self.city) }
    }

    private var citySuggestions: some View {
        ForEach(self.matchingCities.prefix(5), id: \.self) { suggestion in
            Button {
                self.city = suggestion
                self.showCitySuggestions = false
            } label: {
                HStack(spacing: SpacingTokens.xSmall) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(suggestion)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func save() {
        let mealPhotosToDelete = self.allMealPhotos.filter {
            $0.restaurantIdentifier == self.restaurantIdentifier
                && self.removedPhotoIdentifiers.contains($0.photoIdentifier)
        }

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
        }

        for mealPhoto in mealPhotosToDelete {
            self.modelContext.delete(mealPhoto)
        }

        for stagedMealPhoto in self.stagedMealPhotos {
            let mealPhoto = RestaurantMealPhoto(
                photoIdentifier: stagedMealPhoto.photoIdentifier,
                restaurantIdentifier: self.restaurantIdentifier,
                relativePath: stagedMealPhoto.relativePath
            )
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

        let mealPhotos = self.allMealPhotos.filter {
            $0.restaurantIdentifier == self.restaurantIdentifier
        }
        let stagedPaths = self.stagedMealPhotos.map(\.relativePath)

        for mealPhoto in mealPhotos {
            self.modelContext.delete(mealPhoto)
        }

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

// MARK: - EditableMealPhotoThumbnail

private struct EditableMealPhotoThumbnail: View {
    let fileURL: URL
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: self.fileURL, transaction: .init(animation: .smooth)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            ProgressView()
                        }
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }
            }
            .frame(width: 112, height: 112)
            .clipShape(.rect(cornerRadius: 18, style: .continuous))

            Button("Remove Photo", systemImage: "xmark.circle.fill") {
                self.onRemove()
            }
            .labelStyle(.iconOnly)
            .font(.title3)
            .tint(.white)
            .padding(SpacingTokens.xxSmall)
        }
    }
}
