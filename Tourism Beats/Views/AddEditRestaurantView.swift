import SwiftData
import SwiftUI

// MARK: - AddEditRestaurantView

/// A sheet-presented form for creating or editing a restaurant entry.
///
/// When `restaurant` is nil, the form creates a new entry. When editing,
/// it pre-fills fields from the existing restaurant and updates in place.
struct AddEditRestaurantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// The restaurant to edit, or nil for creation mode.
    private let restaurant: Restaurant?

    /// Existing city names for autocomplete suggestions.
    let existingCities: [String]

    // MARK: Form State

    @State private var name: String
    @State private var city: String
    @State private var country: String
    @State private var score: Int?
    @State private var hasScore: Bool
    @State private var scoreValue: Int
    @State private var bestDish: String
    @State private var status: RestaurantStatus
    @State private var notes: String
    @State private var showCitySuggestions: Bool = false

    private var isEditing: Bool { self.restaurant != nil }

    private var canSave: Bool {
        !self.name.trimmingCharacters(in: .whitespaces).isEmpty
            && !self.city.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: Init

    init(restaurant: Restaurant? = nil, existingCities: [String] = []) {
        self.restaurant = restaurant
        self.existingCities = existingCities
        self._name = State(initialValue: restaurant?.name ?? "")
        self._city = State(initialValue: restaurant?.city ?? "")
        self._country = State(initialValue: restaurant?.country ?? "")
        self._score = State(initialValue: restaurant?.clampedScore)
        self._hasScore = State(initialValue: restaurant?.score != nil)
        self._scoreValue = State(initialValue: restaurant?.clampedScore ?? 7)
        self._bestDish = State(initialValue: restaurant?.bestDish ?? "")
        self._status = State(initialValue: restaurant?.status ?? .wantToTry)
        self._notes = State(initialValue: restaurant?.notes ?? "")
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                self.restaurantSection
                self.ratingSection
                self.statusSection
                self.notesSection
            }
            .navigationTitle(self.isEditing ? "Edit Restaurant" : "Add Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { self.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(self.isEditing ? "Save" : "Add") {
                        self.save()
                    }
                    .disabled(!self.canSave)
                    .fontWeight(.semibold)
                }
            }
        }
        .interactiveDismissDisabled(self.hasUnsavedChanges)
    }

    // MARK: - Sections

    private var restaurantSection: some View {
        Section {
            TextField("Restaurant Name", text: self.$name)
                .textContentType(.organizationName)
                .autocorrectionDisabled()

            VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                TextField("City", text: self.$city)
                    .textContentType(.addressCity)
                    .autocorrectionDisabled()
                    .onChange(of: self.city) { _, newValue in
                        self.showCitySuggestions = !newValue.isEmpty
                            && !self.matchingCities.isEmpty
                            && !self.matchingCities.contains(newValue)
                    }

                if self.showCitySuggestions {
                    self.citySuggestions
                }
            }

            TextField("Country", text: self.$country)
                .textContentType(.countryName)
                .autocorrectionDisabled()
        } header: {
            Text("Restaurant")
        }
    }

    private var ratingSection: some View {
        Section {
            Toggle("Rate this restaurant", isOn: self.$hasScore.animation(AnimationTokens.standard))

            if self.hasScore {
                VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                    HStack {
                        Text("Score")
                            .font(TypographyTokens.body)
                        Spacer()
                        Text("\(self.scoreValue)/10")
                            .font(TypographyTokens.songTitle.weight(.bold).monospacedDigit())
                            .foregroundStyle(AppColors.gold)
                    }

                    // Score stepper with visual dots
                    HStack(spacing: 4) {
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
                            .accessibilityLabel("\(index)")
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
                        @unknown default: break
                        }
                    }
                }
            }

            TextField("Best Dish (optional)", text: self.$bestDish)
        } header: {
            Text("Rating")
        }
    }

    private var statusSection: some View {
        Section {
            Picker("Status", selection: self.$status) {
                ForEach(RestaurantStatus.allCases) { s in
                    Label(s.label, systemImage: s.systemImage)
                        .tag(s)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Status")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Add notes (optional)", text: self.$notes, axis: .vertical)
                .lineLimit(3 ... 8)
        } header: {
            Text("Notes")
        }
    }

    // MARK: - City Suggestions

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
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(suggestion)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Save

    private func save() {
        let trimmedName = self.name.trimmingCharacters(in: .whitespaces)
        let trimmedCity = self.city.trimmingCharacters(in: .whitespaces)
        let trimmedCountry = self.country.trimmingCharacters(in: .whitespaces)
        let trimmedDish = self.bestDish.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = self.notes.trimmingCharacters(in: .whitespaces)
        let finalScore = self.hasScore ? self.scoreValue : nil

        if let existing = self.restaurant {
            existing.name = trimmedName
            existing.city = trimmedCity
            existing.country = trimmedCountry
            existing.score = finalScore
            existing.bestDish = trimmedDish.isEmpty ? nil : trimmedDish
            existing.status = self.status
            existing.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        } else {
            let new = Restaurant(
                name: trimmedName,
                city: trimmedCity,
                country: trimmedCountry,
                score: finalScore,
                bestDish: trimmedDish.isEmpty ? nil : trimmedDish,
                status: self.status,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            self.modelContext.insert(new)
        }

        self.dismiss()
    }

    // MARK: - Unsaved Changes

    private var hasUnsavedChanges: Bool {
        if let r = self.restaurant {
            return self.name != r.name
                || self.city != r.city
                || self.country != r.country
                || self.status != r.status
        }
        return !self.name.isEmpty || !self.city.isEmpty
    }
}
