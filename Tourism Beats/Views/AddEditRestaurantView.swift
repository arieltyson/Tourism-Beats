import SwiftData
import SwiftUI

struct AddEditRestaurantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let restaurant: Restaurant?
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

    private var isEditing: Bool {
        self.restaurant != nil
    }

    private var canSave: Bool {
        !self.trimmedName.isEmpty
            && !self.trimmedCity.isEmpty
            && self.locationURLValidationMessage == nil
            && self.menuURLValidationMessage == nil
    }

    init(restaurant: Restaurant? = nil, existingCities: [String] = []) {
        self.restaurant = restaurant
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
                self.ratingSection
                self.linksSection
                self.statusSection
                self.notesSection
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
        let finalScore = self.hasScore ? self.scoreValue : nil
        let normalizedLocationURLString = Self.normalizedURLString(from: self.locationURLString)
        let normalizedMenuURLString = Self.normalizedURLString(from: self.menuURLString)
        let trimmedDish = self.trimmedBestDish
        let trimmedNotes = self.trimmedNotes

        if let restaurant = self.restaurant {
            restaurant.name = self.trimmedName
            restaurant.city = self.trimmedCity
            restaurant.country = self.trimmedCountry
            restaurant.cuisine = self.cuisine
            restaurant.score = finalScore
            restaurant.bestDish = trimmedDish.isEmpty ? nil : trimmedDish
            restaurant.status = self.status
            restaurant.locationURLString = normalizedLocationURLString
            restaurant.menuURLString = normalizedMenuURLString
            restaurant.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        } else {
            let restaurant = Restaurant(
                name: self.trimmedName,
                city: self.trimmedCity,
                country: self.trimmedCountry,
                score: finalScore,
                cuisine: self.cuisine,
                bestDish: trimmedDish.isEmpty ? nil : trimmedDish,
                status: self.status,
                locationURLString: normalizedLocationURLString,
                menuURLString: normalizedMenuURLString,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            self.modelContext.insert(restaurant)
        }

        self.dismiss()
    }

    private var hasUnsavedChanges: Bool {
        guard let restaurant else {
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
        }

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
