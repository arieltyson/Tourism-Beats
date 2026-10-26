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
