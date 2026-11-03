import SwiftUI

/// Every flight being counted down to, with a preview of the next one's card.
struct FlightCountdownView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = FlightCountdownViewModel()
    @State private var editedFlight: CountdownFlight?
    @State private var isAdding = false
    @State private var showsWidgetHelp = false

    var body: some View {
        List {
            if model.nextFlight != nil {
                Section("Preview") {
                    TimelineView(.periodic(from: .now, by: FlightCountdownConfiguration.secondsPerMinute)) { context in
                        if let flight = CountdownFlight.next(in: model.flights, after: context.date) {
                            FlightCountdownCard(flight: flight, date: context.date, photo: model.photos[flight.id])
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            if !model.flights.isEmpty {
                Section("Flights") {
                    ForEach(model.flights) { flight in
                        Button {
                            editedFlight = flight
                        } label: {
                            FlightCountdownRow(flight: flight, photo: model.photos[flight.id], now: .now)
                        }
                        .accessibilityHint("Edits the flight")
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", systemImage: "trash", role: .destructive) { delete(flight) }
                        }
                        .contextMenu {
                            Button("Edit", systemImage: "pencil") { editedFlight = flight }
                            Button("Delete", systemImage: "trash", role: .destructive) { delete(flight) }
                        }
                    }
                }
            }
        }
        .overlay {
            if model.flights.isEmpty {
                if model.isLoading && !model.hasLoaded {
                    ProgressView("Loading Flights")
                } else if !model.hasLoaded {
                    ContentUnavailableView {
                        Label("Flights Unavailable", systemImage: "exclamationmark.icloud")
                    } actions: {
                        Button("Try Again") { Task { await model.load() } }
                    }
                } else {
                    FlightCountdownEmptyState()
                }
            }
        }
        .animation(AnimationTokens.standard, value: model.flights)
        .sensoryFeedback(.success, trigger: model.changeCount)
        .navigationTitle("Flight Countdown")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Add a Widget", systemImage: "info.circle") { showsWidgetHelp = true }
                Button("Add Flight", systemImage: "plus") { isAdding = true }
                    .disabled(!model.hasLoaded || model.isSaving)
            }
        }
        .sheet(isPresented: $isAdding) {
            FlightCountdownForm(model: model)
        }
        .sheet(item: $editedFlight) { flight in
            FlightCountdownForm(model: model, flight: flight)
        }
        .sheet(isPresented: $showsWidgetHelp) {
            let flight = model.nextFlight
            FlightCountdownWidgetHelp(
                flight: flight ?? .sample(from: .now), photo: flight.flatMap { model.photos[$0.id] }
            )
        }
        .alert("Couldn’t Update Flights", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? String(localized: "Please try again."))
        }
        .task { await model.load() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.load() } }
        }
    }

    private func delete(_ flight: CountdownFlight) {
        Task { await model.delete(flight) }
    }
}
