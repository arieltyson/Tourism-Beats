import SwiftUI

struct FlightCountdownForm: View {
    @Environment(\.dismiss) private var dismiss
    let model: FlightCountdownViewModel
    private let originalFlight: CountdownFlight?
    @State private var form: FlightCountdownFormViewModel
    @State private var showsDeleteConfirmation = false
    @State private var showsDiscardConfirmation = false
    @State private var errorMessage: String?

    init(model: FlightCountdownViewModel, flight: CountdownFlight? = nil) {
        self.model = model
        originalFlight = flight
        _form = State(initialValue: FlightCountdownFormViewModel(flight: flight))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Flight") {
                    TextField("Flight number", text: $form.flightNumber, prompt: Text("AC 123"))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("flightNumber")
                    TextField("From", text: $form.origin, prompt: Text("YVR"))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .accessibilityHint("Three-letter departure airport code")
                        .accessibilityIdentifier("flightOrigin")
                    TextField("To", text: $form.destination, prompt: Text("YYZ"))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .accessibilityHint("Three-letter arrival airport code")
                        .accessibilityIdentifier("flightDestination")
                }
                Section {
                    NavigationLink(value: FlightCountdownFormRoute.timeZone) {
                        LabeledContent("Time Zone", value: form.timeZoneLabel)
                    }
                    DatePicker("Departure", selection: $form.departure)
                        .environment(\.timeZone, form.timeZone)
                } header: {
                    Text("Scheduled Departure")
                } footer: {
                    Text("Use the departure airport’s local time. Flight changes aren’t updated automatically.")
                }
                if originalFlight != nil {
                    Section {
                        Button("Delete Flight", systemImage: "trash", role: .destructive) {
                            showsDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationDestination(for: FlightCountdownFormRoute.self) { _ in
                FlightTimeZonePicker(selection: form.timeZoneIdentifier, referenceDate: form.departure) {
                    form.timeZoneIdentifier = $0
                }
            }
            .navigationTitle(form.isEditing ? "Edit Flight" : "Add Flight")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(model.isSaving)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if form.hasChanges { showsDiscardConfirmation = true }
                        else { dismiss() }
                    }
                        .disabled(model.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await model.save(form.flight) { dismiss() }
                            else { errorMessage = model.errorMessage; model.errorMessage = nil }
                        }
                    }
                    .bold()
                    .disabled(!form.canSave || model.isSaving)
                    .accessibilityIdentifier("saveFlight")
                }
            }
            .confirmationDialog("Delete this flight?", isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Flight", role: .destructive) {
                    guard let originalFlight else { return }
                    Task {
                        if await model.delete(originalFlight) { dismiss() }
                        else { errorMessage = model.errorMessage; model.errorMessage = nil }
                    }
                }
            }
            .confirmationDialog("Discard changes?", isPresented: $showsDiscardConfirmation, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) { dismiss() }
            }
            .alert("Couldn't Save Flight", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "Please try again.") }
        }
        .interactiveDismissDisabled(form.hasChanges || model.isSaving)
    }
}
