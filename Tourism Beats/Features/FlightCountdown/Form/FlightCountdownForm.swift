import SwiftUI

/// Adds or edits a flight: who's flying with whom, where, and when.
struct FlightCountdownForm: View {
    @Environment(\.dismiss) private var dismiss
    let model: FlightCountdownViewModel
    private let originalFlight: CountdownFlight?
    @State private var form: FlightCountdownFormViewModel
    @State private var showsDeleteConfirmation = false
    @State private var showsDiscardConfirmation = false
    @State private var errorMessage: String?
    @FocusState private var isEditingNumber: Bool

    init(model: FlightCountdownViewModel, flight: CountdownFlight? = nil) {
        self.model = model
        originalFlight = flight
        _form = State(initialValue: FlightCountdownFormViewModel(
            flight: flight, photo: flight.flatMap { model.photos[$0.id] }
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Flight") {
                    NavigationLink(value: FlightCountdownFormRoute.airline) {
                        LabeledContent("Airline") {
                            if let airline = form.airline {
                                Text(airline.name)
                            } else {
                                FlightFormPlaceholder()
                            }
                        }
                    }
                    .accessibilityIdentifier("flightAirline")
                    TextField("Flight Number", text: $form.flightNumber, prompt: Text("Flight Number"))
                        .keyboardType(.asciiCapableNumberPad)
                        .focused($isEditingNumber)
                        .accessibilityIdentifier("flightNumber")
                }
                Section("Route") {
                    NavigationLink(value: FlightCountdownFormRoute.origin) {
                        FlightAirportRow(title: "From", systemImage: "airplane.departure", airport: form.origin)
                    }
                    .accessibilityIdentifier("flightOrigin")
                    NavigationLink(value: FlightCountdownFormRoute.destination) {
                        FlightAirportRow(title: "To", systemImage: "airplane.arrival", airport: form.destination)
                    }
                    .accessibilityIdentifier("flightDestination")
                }
                Section {
                    DatePicker("Departs", selection: $form.departure)
                        .environment(\.timeZone, form.timeZone)
                    NavigationLink(value: FlightCountdownFormRoute.timeZone) {
                        LabeledContent("Time Zone", value: form.timeZoneLabel)
                    }
                } header: {
                    Text("Departure")
                } footer: {
                    Text(form.departureFooter)
                }
                Section("Card") {
                    FlightCountdownCard(flight: form.flight, date: .now, photo: form.photo)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .accessibilityLabel("Card preview")
                    FlightCardDesignPicker(form: form)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                if originalFlight != nil {
                    Section {
                        Button("Delete Flight", systemImage: "trash", role: .destructive) {
                            showsDeleteConfirmation = true
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(for: FlightCountdownFormRoute.self) { route in
                FlightCountdownFormDestination(route: route, form: form)
            }
            .navigationTitle(form.isEditing ? "Edit Flight" : "Add Flight")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(model.isSaving)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        if form.hasChanges { showsDiscardConfirmation = true } else { dismiss() }
                    }
                    .disabled(model.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", role: .confirm, action: save)
                        .disabled(!form.canSave || model.isSaving)
                        .accessibilityIdentifier("saveFlight")
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { isEditingNumber = false }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .confirmationDialog("Delete this flight?", isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Flight", role: .destructive, action: delete)
            }
            .confirmationDialog("Discard changes?", isPresented: $showsDiscardConfirmation, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) { dismiss() }
            }
            .alert("Couldn’t Save Flight", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? String(localized: "Please try again."))
            }
            .alert("Couldn’t Use This Photo", isPresented: Binding(
                get: { form.photoErrorMessage != nil }, set: { if !$0 { form.photoErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { form.photoErrorMessage = nil }
            } message: {
                Text(form.photoErrorMessage ?? String(localized: "Try another photo."))
            }
        }
        .interactiveDismissDisabled(form.hasChanges || model.isSaving)
    }

    private func save() {
        isEditingNumber = false
        Task {
            if await model.save(form.flight, photo: form.photoChange) { dismiss() } else { takeError() }
        }
    }

    private func delete() {
        guard let originalFlight else { return }
        Task {
            if await model.delete(originalFlight) { dismiss() } else { takeError() }
        }
    }

    private func takeError() {
        errorMessage = model.errorMessage
        model.errorMessage = nil
    }
}
