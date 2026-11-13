import SwiftData
import SwiftUI

// MARK: - AddEditTripView

/// Sheet form for creating or editing a trip.
///
/// Only the trip name and city are required. Country, hotel, dates, notes,
/// and status remain lightweight and optional so users can sketch a plan quickly.
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
    @State private var stay: TripStay?
    @State private var budget: TripBudget?
    @State private var isSearchingStay = false
    @State private var saveErrorMessage: String?
    @State private var catalog = TripsViewModel()
    @State private var suggestsPlan: Bool = false
    @State private var planRequest: TripPlanRequest?

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

    /// The catalog city the trip is headed to, if it's one the app knows.
    private var catalogCity: CityModel? {
        self.catalog.cityModel(named: self.trimmedCity, in: self.trimmedCountry)
    }

    /// The catalog city a new trip is headed to, which a plan can be suggested for.
    private var plannableCity: CityModel? {
        self.isEditing ? nil : self.catalogCity
    }

    /// How long the trip runs: its dates' days, or the days it already has.
    private var tripLength: TripLength {
        if self.hasDates {
            return TripLength(days: self.generatedDayDates.count)
        }
        return TripLength(days: self.trip?.dayCount ?? 1)
    }

    /// What a trip like this typically costs, in the budget's currency or
    /// the traveller's own.
    private var typicalBudget: TripBudget {
        TravelCostEstimator().typicalBudget(
            for: self.tripLength,
            countryCode: self.catalogCity?.country.code ?? self.formViewModel.selectedCountryCode,
            currencyCode: self.budget?.currencyCode ?? Locale.current.currency?.identifier
                ?? TravelCostEstimator.fallbackCurrencyCode
        )
    }

    private var stayArea: TripStaySearchArea {
        TripStaySearchArea(
            cityName: self.catalogCity?.name ?? self.trimmedCity,
            countryName: self.catalogCity?.country.name ?? self.trimmedCountry,
            center: self.catalogCity?.coordinate
        )
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
        self._stay = State(initialValue: trip?.stay)
        self._budget = State(initialValue: trip?.budget)
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

                if !self.trimmedCity.isEmpty {
                    TripStaySection(
                        stay: self.stay,
                        cityName: self.trimmedCity,
                        onChoose: { self.isSearchingStay = true },
                        onRemove: { self.stay = nil }
                    )
                }

                TripDatesSection(
                    hasDates: self.$hasDates,
                    startDate: self.$startDate,
                    endDate: self.$endDate
                )

                TripBudgetSection(budget: self.budget)

                if let plannableCity {
                    TripPlanSection(
                        suggestsPlan: self.$suggestsPlan,
                        cityName: plannableCity.name,
                        stayName: self.stay?.name
                    )
                }

                TripStatusSection(status: self.$status)

                TripNotesSection(notes: self.$notes)
            }
            .keyboardDismissal()
            .navigationDestination(for: TripBudgetRoute.self) { _ in
                TripBudgetEditorView(
                    budget: self.$budget,
                    typicalBudget: self.typicalBudget,
                    length: self.tripLength,
                    placeName: self.catalogCity?.name ?? self.trimmedCity
                )
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
        .sheet(isPresented: self.$isSearchingStay) {
            TripStaySearchView(area: self.stayArea) { self.stay = $0 }
        }
        .sheet(item: self.$planRequest, onDismiss: { self.dismiss() }) { request in
            TripSuggestionsView(
                trip: request.trip,
                city: request.city,
                scope: .trip,
                onApplied: { addedCount in
                    guard addedCount > 0 else { return }
                    AccessibilityAnnouncer.announceActivitiesAdded(count: addedCount)
                }
            )
        }
        .task(id: self.suggestsPlan ? self.plannableCity?.id : nil) {
            // Warm the city's guides while the form is filled in, so the plan
            // is ready sooner once the trip is added.
            guard self.suggestsPlan, let plannableCity = self.plannableCity else { return }
            await TripSuggestionsViewModel.prefetchGuides(for: plannableCity)
        }
        .interactiveDismissDisabled(self.hasUnsavedChanges)
        .onChange(of: self.formViewModel.selectedCountryCode) { _, _ in
            self.synchronizeCountryField()
        }
        .onChange(of: self.country) { _, newValue in
            self.formViewModel.synchronizeCountrySelection(with: newValue)
        }
        .onChange(of: self.trimmedCity) { _, _ in
            // A hotel belongs to the city it was found in.
            self.stay = nil
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
                || self.stay != trip.stay
                || self.budget != trip.budget
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
            || self.stay != nil
            || self.budget != nil
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

            // A new trip planned from the start opens its suggestions next;
            // the form closes once they're reviewed.
            if self.suggestsPlan, let city = self.plannableCity {
                self.planRequest = TripPlanRequest(trip: savedTrip, city: city)
            } else {
                self.dismiss()
            }
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
            trip.stay = self.stay
            trip.budget = self.budget
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
            newTrip.stay = self.stay
            newTrip.budget = self.budget
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
