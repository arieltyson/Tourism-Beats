import SwiftData
import SwiftUI

// MARK: - AddEditActivityView

/// Sheet form for creating or editing a trip activity.
///
/// Only the activity name is required. Type, time, location, notes, and status
/// are all optional, supporting users who prefer minimal planning detail.
struct AddEditActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let activity: TripActivity?
    private let day: TripDay

    @State private var name: String
    @State private var location: String
    @State private var type: ActivityType
    @State private var hasTime: Bool
    @State private var time: Date
    @State private var status: ActivityStatus
    @State private var notes: String

    private var isEditing: Bool { self.activity != nil }

    private var canSave: Bool {
        !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Create mode: pass `day` for the target day, `activity` as nil.
    /// Edit mode: pass the existing `activity` and its owning `day`.
    init(day: TripDay, activity: TripActivity? = nil) {
        self.day = day
        self.activity = activity
        self._name = State(initialValue: activity?.name ?? "")
        self._location = State(initialValue: activity?.location ?? "")
        self._type = State(initialValue: activity?.type ?? .other)
        self._hasTime = State(initialValue: activity?.time != nil)
        self._time = State(initialValue: activity?.time ?? Self.defaultTime(for: day))
        self._status = State(initialValue: activity?.activityStatus ?? .planned)
        self._notes = State(initialValue: activity?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                self.activitySection
                self.typeSection
                self.timeSection
                self.statusSection
                self.notesSection
            }
            .navigationTitle(self.isEditing ? "Edit Activity" : "Add Activity")
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

    private var activitySection: some View {
        Section("Activity") {
            TextField("Activity Name", text: self.$name)
                .autocorrectionDisabled()

            TextField("Location (optional)", text: self.$location)
                .textContentType(.location)
                .autocorrectionDisabled()
        }
    }

    private var typeSection: some View {
        Section("Type") {
            Picker("Activity Type", selection: self.$type) {
                ForEach(ActivityType.allCases) { activityType in
                    Label(activityType.label, systemImage: activityType.systemImage)
                        .tag(activityType)
                }
            }
        }
    }

    private var timeSection: some View {
        Section("Time") {
            Toggle("Set a time", isOn: self.$hasTime.animation(AnimationTokens.standard))
                .tint(AppColors.coral)

            if self.hasTime {
                DatePicker(
                    "Time",
                    selection: self.$time,
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: self.$status) {
                ForEach(ActivityStatus.allCases) { activityStatus in
                    Label(activityStatus.label, systemImage: activityStatus.systemImage)
                        .tag(activityStatus)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Notes (optional)", text: self.$notes, axis: .vertical)
                .lineLimit(2 ... 6)
        }
    }

    // MARK: - Save

    private func save() {
        let trimmedName = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = self.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = self.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = self.activity {
            existing.name = trimmedName
            existing.location = trimmedLocation.isEmpty ? nil : trimmedLocation
            existing.type = self.type
            existing.time = self.hasTime ? self.time : nil
            existing.activityStatus = self.status
            existing.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        } else {
            let newActivity = TripActivity(
                name: trimmedName,
                time: self.hasTime ? self.time : nil,
                type: self.type,
                status: self.status,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                location: trimmedLocation.isEmpty ? nil : trimmedLocation,
                day: self.day
            )
            self.modelContext.insert(newActivity)
        }

        self.dismiss()
    }

    private var hasUnsavedChanges: Bool {
        if let a = self.activity {
            return self.name != a.name || self.type != a.type || self.status != a.activityStatus
        }
        return !self.name.isEmpty
    }

    /// Generates a sensible default time based on the day's existing activities.
    private static func defaultTime(for day: TripDay) -> Date {
        if let lastTime = day.sortedActivities.compactMap(\.time).last {
            return Calendar.current.date(byAdding: .hour, value: 1, to: lastTime) ?? .now
        }
        // Default to 9 AM
        var components = Calendar.current.dateComponents([.year, .month, .day], from: day.date ?? .now)
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }
}
