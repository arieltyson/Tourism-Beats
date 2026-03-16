import SwiftData
import SwiftUI

// MARK: - AddEditTripView

/// Sheet form for creating or editing a trip.
///
/// Only name and city are required — all other fields are optional,
/// keeping the experience lightweight for users who prefer minimal detail.
struct AddEditTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let trip: Trip?

    @State private var name: String
    @State private var city: String
    @State private var country: String
    @State private var hasDates: Bool
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var status: TripStatus
    @State private var notes: String

    private var isEditing: Bool { self.trip != nil }

    private var canSave: Bool {
        !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !self.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(trip: Trip? = nil) {
        self.trip = trip
        self._name = State(initialValue: trip?.name ?? "")
        self._city = State(initialValue: trip?.city ?? "")
        self._country = State(initialValue: trip?.country ?? "")
        self._hasDates = State(initialValue: trip?.startDate != nil)
        self._startDate = State(initialValue: trip?.startDate ?? .now)
        self._endDate = State(initialValue: trip?.endDate ?? Calendar.current.date(byAdding: .day, value: 5, to: .now)!)
        self._status = State(initialValue: trip?.status ?? .upcoming)
        self._notes = State(initialValue: trip?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                self.tripDetailsSection
                self.datesSection
                self.statusSection
                self.notesSection
            }
            .navigationTitle(self.isEditing ? "Edit Trip" : "New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { self.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(self.isEditing ? "Save" : "Add") { self.save() }
                        .disabled(!self.canSave)
                        .bold()
                }
            }
        }
        .interactiveDismissDisabled(self.hasUnsavedChanges)
    }

    // MARK: - Sections

    private var tripDetailsSection: some View {
        Section("Trip Details") {
            TextField("Trip Name", text: self.$name)
                .autocorrectionDisabled()

            TextField("City", text: self.$city)
                .textContentType(.addressCity)
                .autocorrectionDisabled()

            TextField("Country (optional)", text: self.$country)
                .textContentType(.countryName)
                .autocorrectionDisabled()
        }
    }

    private var datesSection: some View {
        Section("Travel Dates") {
            Toggle("Set travel dates", isOn: self.$hasDates.animation(AnimationTokens.standard))
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
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: self.$status) {
                ForEach(TripStatus.allCases) { tripStatus in
                    Label(tripStatus.label, systemImage: tripStatus.systemImage)
                        .tag(tripStatus)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Trip notes (optional)", text: self.$notes, axis: .vertical)
                .lineLimit(3 ... 8)
        }
    }

    // MARK: - Save

    private func save() {
        let trimmedName = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCity = self.city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCountry = self.country.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = self.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = self.trip {
            existing.name = trimmedName
            existing.city = trimmedCity
            existing.country = trimmedCountry
            existing.startDate = self.hasDates ? self.startDate : nil
            existing.endDate = self.hasDates ? self.endDate : nil
            existing.status = self.status
            existing.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        } else {
            let newTrip = Trip(
                name: trimmedName,
                city: trimmedCity,
                country: trimmedCountry,
                startDate: self.hasDates ? self.startDate : nil,
                endDate: self.hasDates ? self.endDate : nil,
                status: self.status
            )
            if !trimmedNotes.isEmpty {
                newTrip.notes = trimmedNotes
            }
            self.modelContext.insert(newTrip)

            // Auto-create first day
            let firstDay = TripDay(dayNumber: 1, date: self.hasDates ? self.startDate : nil, trip: newTrip)
            self.modelContext.insert(firstDay)
        }

        self.dismiss()
    }

    private var hasUnsavedChanges: Bool {
        if let t = self.trip {
            return self.name != t.name
                || self.city != t.city
                || self.country != t.country
                || self.status != t.status
        }
        return !self.name.isEmpty || !self.city.isEmpty
    }
}
