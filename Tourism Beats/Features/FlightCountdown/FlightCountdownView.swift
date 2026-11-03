import SwiftUI

struct FlightCountdownView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = FlightCountdownViewModel()
    @State private var editedFlight: CountdownFlight?
    @State private var isAdding = false
    @State private var showsWidgetHelp = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingTokens.large) {
                if model.isLoading && !model.hasLoaded {
                    ProgressView("Loading flights")
                        .frame(maxWidth: .infinity)
                } else if !model.hasLoaded {
                    ContentUnavailableView {
                        Label("Flights Unavailable", systemImage: "exclamationmark.icloud")
                    } actions: {
                        Button("Try Again") { Task { await model.load() } }
                    }
                } else if model.flights.isEmpty {
                    ContentUnavailableView {
                        Label("Your Next Takeoff", systemImage: "airplane.departure")
                    } description: {
                        Text("Add a flight to start your countdown.")
                    } actions: {
                        Button("Add Flight", systemImage: "plus") { isAdding = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    TimelineView(.periodic(from: .now, by: FlightCountdownConfiguration.secondsPerMinute)) { context in
                        if let flight = CountdownFlight.next(in: model.flights, after: context.date) {
                            FlightCountdownHero(flight: flight, date: context.date)
                        }
                    }
                    VStack(spacing: SpacingTokens.small) {
                        ForEach(model.flights) { flight in
                            Button {
                                editedFlight = flight
                            } label: {
                                FlightCountdownRow(flight: flight)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Edit flight")
                        }
                    }
                }
            }
            .padding(SpacingTokens.medium)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Flight Countdown")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Add Widget", systemImage: "square.grid.2x2") { showsWidgetHelp = true }
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
            FlightCountdownWidgetHelp()
        }
        .alert("Couldn't Update Flights", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "Please try again.")
        }
        .task { await model.load() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.load() } }
        }
    }
}
