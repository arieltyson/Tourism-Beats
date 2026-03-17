import SwiftData
import SwiftUI

// MARK: - AddEditTripView

/// Sheet form for creating or editing a trip.
///
/// Only the trip name and city are required. Country, dates, notes, and status
/// remain lightweight and optional so users can sketch a plan quickly.
struct AddEditTripView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let trip: Trip?

    @State private var formViewModel: TripFormViewModel
    @State private var name: String
    @State private var city: String
    @State private var country: String
    @State private var hasDates: Bool
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var status: TripStatus
    @State private var notes: String
    @State private var saveErrorMessage: String?

    private var isEditing: Bool {
        self.trip != nil
    }

    private var canSave: Bool {
        !self.trimmedName.isEmpty && !self.trimmedCity.isEmpty
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

    private var normalizedNotes: String? {
        let trimmedNotes = self.notes.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmedNotes.isEmpty ? nil : trimmedNotes
    }

    private var citySuggestions: [CityModel] {
        let trimmedQuery = self.trimmedCity
        guard
            !trimmedQuery.isEmpty
                || !self.formViewModel.selectedCountryCode.isEmpty
        else {
            return []
        }

        let suggestions = self.formViewModel.matchingCities(for: trimmedQuery)
        return Array(suggestions.prefix(8))
    }

    init(trip: Trip? = nil) {
        self.trip = trip

        let defaultStartDate = trip?.startDate ?? Date.now
        let defaultEndDate =
            trip?.endDate
            ?? Calendar.current.date(
                byAdding: .day,
                value: 5,
                to: defaultStartDate
            )
            ?? defaultStartDate

        self._formViewModel = State(
            initialValue: TripFormViewModel(countryName: trip?.country ?? "")
        )
        self._name = State(initialValue: trip?.name ?? "")
        self._city = State(initialValue: trip?.city ?? "")
        self._country = State(initialValue: trip?.country ?? "")
        self._hasDates = State(initialValue: trip?.startDate != nil)
        self._startDate = State(initialValue: defaultStartDate)
        self._endDate = State(initialValue: defaultEndDate)
        self._status = State(initialValue: trip?.status ?? .upcoming)
        self._notes = State(initialValue: trip?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TripBasicsSection(
                    name: self.$name,
                    city: self.$city,
                    countryDisplayLabel: self.countryDisplayLabel,
                    hasCountryValue: self.hasCountryValue,
                    onSelectCountry: {
                        self.formViewModel.isCountryPickerPresented = true
                    }
                )

                if !self.citySuggestions.isEmpty {
                    TripCitySuggestionsSection(
                        suggestions: self.citySuggestions,
                        onSelectCity: self.applyCitySelection
                    )
                }

                TripDatesSection(
                    hasDates: self.$hasDates,
                    startDate: self.$startDate,
                    endDate: self.$endDate
                )

                TripStatusSection(status: self.$status)

                TripNotesSection(notes: self.$notes)
            }
            .navigationTitle(self.isEditing ? "Edit Trip" : "New Trip")
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
                    .bold()
                }
            }
        }
        .sheet(isPresented: self.$formViewModel.isCountryPickerPresented) {
            SearchableCountryPicker(
                selectedCode: self.$formViewModel.selectedCountryCode
            )
        }
        .interactiveDismissDisabled(self.hasUnsavedChanges)
        .onChange(of: self.formViewModel.selectedCountryCode) { _, _ in
            self.synchronizeCountryField()
        }
        .onChange(of: self.country) { _, newValue in
            self.formViewModel.synchronizeCountrySelection(with: newValue)
        }
        .alert(
            "Couldn't Save Trip",
            isPresented: self.saveErrorPresented
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.saveErrorMessage ?? "Please try again.")
        }
    }

    private var hasUnsavedChanges: Bool {
        if let trip {
            return self.trimmedName != trip.name
                || self.trimmedCity != trip.city
                || self.trimmedCountry != trip.country
                || self.status != trip.status
                || self.normalizedNotes != trip.trimmedNotes
                || self.hasDates != (trip.startDate != nil)
                || !Self.sameDay(
                    self.hasDates ? self.startDate : nil,
                    trip.startDate
                )
                || !Self.sameDay(
                    self.hasDates ? self.endDate : nil,
                    trip.endDate
                )
        }

        return !self.trimmedName.isEmpty
            || !self.trimmedCity.isEmpty
            || !self.trimmedCountry.isEmpty
            || self.hasDates
            || self.status != .upcoming
            || self.normalizedNotes != nil
    }

    private var saveErrorPresented: Binding<Bool> {
        Binding(
            get: { self.saveErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    self.saveErrorMessage = nil
                }
            }
        )
    }

    private var countryDisplayLabel: String {
        if !self.formViewModel.selectedCountryName.isEmpty {
            return self.formViewModel.selectedCountryDisplayLabel
        }

        return self.trimmedCountry.isEmpty
            ? "Choose a country" : self.trimmedCountry
    }

    private var hasCountryValue: Bool {
        !self.trimmedCountry.isEmpty
            || !self.formViewModel.selectedCountryName.isEmpty
    }

    private func synchronizeCountryField() {
        let selectedCountryName = self.formViewModel.selectedCountryName
        guard !selectedCountryName.isEmpty else { return }
        self.country = selectedCountryName
    }

    private func applyCitySelection(_ cityModel: CityModel) {
        let selection = self.formViewModel.applySelection(for: cityModel)
        self.city = selection.cityName
        self.country = selection.countryName
    }

    private func save() {
        do {
            let savedTrip = try self.persistTrip()

            if !savedTrip.isSample {
                try TripSeedService.registerUserCreatedTrip(in: self.modelContext)
            }

            self.dismiss()
        } catch {
            self.saveErrorMessage = error.localizedDescription
        }
    }

    private func persistTrip() throws -> Trip {
        if let trip {
            trip.name = self.trimmedName
            trip.city = self.trimmedCity
            trip.country = self.trimmedCountry
            trip.startDate =
                self.hasDates
                ? Calendar.current.startOfDay(for: self.startDate) : nil
            trip.endDate =
                self.hasDates
                ? Calendar.current.startOfDay(for: self.endDate) : nil
            trip.status = self.status
            trip.notes = self.normalizedNotes
            self.synchronizeDays(for: trip)
            if self.modelContext.hasChanges {
                try self.modelContext.save()
            }
            return trip
        } else {
            let newTrip = Trip(
                name: self.trimmedName,
                city: self.trimmedCity,
                country: self.trimmedCountry,
                startDate: self.hasDates
                    ? Calendar.current.startOfDay(for: self.startDate) : nil,
                endDate: self.hasDates
                    ? Calendar.current.startOfDay(for: self.endDate) : nil,
                notes: self.normalizedNotes,
                status: self.status
            )
            self.modelContext.insert(newTrip)
            self.createInitialDays(for: newTrip)
            if self.modelContext.hasChanges {
                try self.modelContext.save()
            }
            return newTrip
        }
    }

    private func createInitialDays(for trip: Trip) {
        let generatedDates = self.generatedDayDates

        if generatedDates.isEmpty {
            self.modelContext.insert(TripDay(dayNumber: 1, trip: trip))
            return
        }

        for (index, date) in generatedDates.enumerated() {
            self.modelContext.insert(
                TripDay(
                    dayNumber: index + 1,
                    date: date,
                    trip: trip
                )
            )
        }
    }

    private func synchronizeDays(for trip: Trip) {
        let existingDays = trip.sortedDays

        guard !existingDays.isEmpty else {
            self.createInitialDays(for: trip)
            return
        }

        self.renumberDays(for: trip)

        guard self.hasDates else { return }

        let generatedDates = self.generatedDayDates
        guard !generatedDates.isEmpty else { return }

        let updatedDays = trip.sortedDays
        for (index, day) in updatedDays.enumerated() {
            if index < generatedDates.count {
                day.date = generatedDates[index]
            } else if day.activityCount == 0 {
                day.date = nil
            }
        }

        guard updatedDays.count < generatedDates.count else { return }

        for index in updatedDays.count ..< generatedDates.count {
            self.modelContext.insert(
                TripDay(
                    dayNumber: index + 1,
                    date: generatedDates[index],
                    trip: trip
                )
            )
        }
    }

    private func renumberDays(for trip: Trip) {
        for (index, day) in trip.sortedDays.enumerated() {
            day.dayNumber = index + 1
        }
    }

    private var generatedDayDates: [Date] {
        guard self.hasDates else { return [] }

        let calendar = Calendar.current
        let normalizedStartDate = calendar.startOfDay(for: self.startDate)
        let normalizedEndDate = calendar.startOfDay(for: self.endDate)
        var currentDate = normalizedStartDate
        var dates: [Date] = []

        while currentDate <= normalizedEndDate {
            dates.append(currentDate)

            guard
                let nextDate = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: currentDate
                )
            else {
                break
            }

            currentDate = nextDate
        }

        return dates
    }

    private static func sameDay(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            true
        case let (.some(leftDate), .some(rightDate)):
            Calendar.current.isDate(leftDate, inSameDayAs: rightDate)
        default:
            false
        }
    }
}

// MARK: - TripBasicsSection

private struct TripBasicsSection: View {
    @Binding var name: String
    @Binding var city: String
    let countryDisplayLabel: String
    let hasCountryValue: Bool
    let onSelectCountry: () -> Void

    var body: some View {
        Section {
            TextField("Trip Name", text: self.$name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            TripCountryPickerField(
                countryDisplayLabel: self.countryDisplayLabel,
                hasCountryValue: self.hasCountryValue,
                onSelectCountry: self.onSelectCountry
            )

            TextField("City", text: self.$city)
                .textContentType(.addressCity)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        } header: {
            Text("Trip Details")
        } footer: {
            Text(
                "Only the trip name and city are required. Dates, notes, and activities can stay flexible."
            )
        }
    }
}

// MARK: - TripCountryPickerField

private struct TripCountryPickerField: View {
    let countryDisplayLabel: String
    let hasCountryValue: Bool
    let onSelectCountry: () -> Void

    var body: some View {
        Button(action: self.onSelectCountry) {
            ViewThatFits(in: .horizontal) {
                TripCountryPickerFieldInlineContent(
                    countryDisplayLabel: self.countryDisplayLabel,
                    hasCountryValue: self.hasCountryValue
                )

                TripCountryPickerFieldStackedContent(
                    countryDisplayLabel: self.countryDisplayLabel,
                    hasCountryValue: self.hasCountryValue
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            self.hasCountryValue
                ? "Country, \(self.countryDisplayLabel)"
                : "Country, Choose a country"
        )
        .accessibilityHint("Opens the list of countries")
        .accessibilityInputLabels(["Country", "Choose Country"])
    }
}

// MARK: - TripCountryPickerFieldInlineContent

private struct TripCountryPickerFieldInlineContent: View {
    let countryDisplayLabel: String
    let hasCountryValue: Bool

    var body: some View {
        HStack(alignment: .center, spacing: SpacingTokens.small) {
            Label("Country", systemImage: "globe")
                .foregroundStyle(.primary)

            Spacer(minLength: SpacingTokens.small)

            HStack(alignment: .center, spacing: SpacingTokens.xSmall) {
                Text(self.countryDisplayLabel)
                    .foregroundStyle(self.hasCountryValue ? .secondary : .tertiary)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}

// MARK: - TripCountryPickerFieldStackedContent

private struct TripCountryPickerFieldStackedContent: View {
    let countryDisplayLabel: String
    let hasCountryValue: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            Label("Country", systemImage: "globe")
                .foregroundStyle(.primary)

            HStack(alignment: .center, spacing: SpacingTokens.xSmall) {
                Text(self.countryDisplayLabel)
                    .foregroundStyle(self.hasCountryValue ? .secondary : .tertiary)
                    .lineLimit(2)

                Spacer(minLength: SpacingTokens.small)

                Image(systemName: "chevron.down")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - TripCitySuggestionsSection

private struct TripCitySuggestionsSection: View {
    let suggestions: [CityModel]
    let onSelectCity: (CityModel) -> Void

    var body: some View {
        Section {
            ForEach(self.suggestions) { city in
                Button {
                    self.onSelectCity(city)
                } label: {
                    HStack(spacing: SpacingTokens.small) {
                        VStack(
                            alignment: .leading,
                            spacing: SpacingTokens.xxSmall
                        ) {
                            Text(city.name)
                                .foregroundStyle(.primary)

                            Text("\(city.country.flag) \(city.country.name)")
                                .font(TypographyTokens.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.left")
                            .foregroundStyle(AppColors.coral)
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Suggested Cities")
        }
    }
}

// MARK: - TripDatesSection

private struct TripDatesSection: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var hasDates: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date

    var body: some View {
        Section {
            Toggle(
                "Set travel dates",
                isOn: self.$hasDates.animation(
                    self.reduceMotion ? .none : AnimationTokens.standard
                )
            )
            .tint(AppColors.coral)

            if self.hasDates {
                DatePicker(
                    "Start",
                    selection: self.$startDate,
                    displayedComponents: .date
                )

                DatePicker(
                    "End",
                    selection: self.$endDate,
                    in: self.startDate...,
                    displayedComponents: .date
                )
            }
        } header: {
            Text("Travel Dates")
        } footer: {
            if self.hasDates {
                Text(
                    "Saving dates automatically creates itinerary days for the range you choose."
                )
            }
        }
    }
}

// MARK: - TripStatusSection

private struct TripStatusSection: View {
    @Binding var status: TripStatus

    var body: some View {
        Section {
            Picker("Status", selection: self.$status) {
                ForEach(TripStatus.allCases) { tripStatus in
                    Label(tripStatus.label, systemImage: tripStatus.systemImage)
                        .tag(tripStatus)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Status")
        }
    }
}

// MARK: - TripNotesSection

private struct TripNotesSection: View {
    @Binding var notes: String

    var body: some View {
        Section {
            TextField(
                "Trip notes (optional)",
                text: self.$notes,
                axis: .vertical
            )
            .lineLimit(3 ... 8)
        } header: {
            Text("Notes")
        }
    }
}
