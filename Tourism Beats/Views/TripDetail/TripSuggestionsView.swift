import SwiftData
import SwiftUI

// MARK: - TripSuggestionsView

/// Sheet that proposes activities from a city's guide, lets the user review
/// them per day, and adds the ones they keep.
struct TripSuggestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: TripSuggestionsViewModel
    @State private var stayRecommendations: TripStayRecommendationsViewModel?
    @State private var saveErrorMessage: String?

    private let trip: Trip
    private let onApplied: (Int) -> Void

    init(
        trip: Trip,
        city: CityModel,
        scope: TripSuggestionsViewModel.Scope,
        onApplied: @escaping (Int) -> Void
    ) {
        self._viewModel = State(
            initialValue: TripSuggestionsViewModel(trip: trip, city: city, scope: scope)
        )
        // A whole-trip plan for a trip without a hotel also suggests where to stay.
        if case .trip = scope, trip.stay == nil {
            self._stayRecommendations = State(
                initialValue: TripStayRecommendationsViewModel(trip: trip, city: city)
            )
        }
        self.trip = trip
        self.onApplied = onApplied
    }

    var body: some View {
        NavigationStack {
            self.content
                .navigationTitle(self.viewModel.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { self.dismiss() }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(self.viewModel.addButtonTitle) { self.apply() }
                            .bold()
                            .accessibilityLabel(self.viewModel.addButtonAccessibilityLabel)
                            .disabled(!self.canApply)
                    }
                }
        }
        .task {
            await self.viewModel.load()
        }
        .task {
            await self.stayRecommendations?.load()
        }
        .sensoryFeedback(.selection, trigger: self.viewModel.selectedSuggestionIDs)
        .sensoryFeedback(.selection, trigger: self.stayRecommendations?.selectedStayID)
        .alert(
            "Couldn't Add Activities",
            isPresented: self.saveErrorPresented
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.saveErrorMessage ?? "Please try again.")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch self.viewModel.state {
        case .loading:
            ProgressView {
                Text("Finding the best of \(self.viewModel.city.name)…")
                    .font(TypographyTokens.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .unavailable(title, message, canRetry):
            ContentUnavailableView {
                Label(title, systemImage: "sparkles")
            } description: {
                Text(message)
            } actions: {
                if canRetry {
                    Button("Try Again", systemImage: "arrow.clockwise") {
                        Task { await self.viewModel.load() }
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.coral)
                }
            }

        case let .loaded(days):
            TripSuggestionsList(
                viewModel: self.viewModel,
                days: days,
                stayRecommendations: self.stayRecommendations
            )
        }
    }

    private var canApply: Bool {
        guard case .loaded = self.viewModel.state else { return false }
        return self.viewModel.selectedCount > 0 || self.stayRecommendations?.selectedStay != nil
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

    private func apply() {
        do {
            if let stay = self.stayRecommendations?.selectedStay {
                self.trip.stay = stay
            }
            // Saving the activities saves the hotel with them.
            let addedCount = try self.viewModel.applySelection(in: self.modelContext)
            self.onApplied(addedCount)
            self.dismiss()
        } catch {
            self.saveErrorMessage = error.localizedDescription
        }
    }
}
