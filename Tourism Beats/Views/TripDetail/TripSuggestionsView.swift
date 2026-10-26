import SwiftData
import SwiftUI

// MARK: - TripSuggestionsView

/// Sheet that proposes activities from a city's guide, lets the user review
/// them per day, and adds the ones they keep.
struct TripSuggestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: TripSuggestionsViewModel
    @State private var saveErrorMessage: String?

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
        .sensoryFeedback(.selection, trigger: self.viewModel.selectedSuggestionIDs)
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
                days: days
            )
        }
    }

    private var canApply: Bool {
        guard case .loaded = self.viewModel.state else { return false }
        return self.viewModel.selectedCount > 0
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
            let addedCount = try self.viewModel.applySelection(in: self.modelContext)
            self.onApplied(addedCount)
            self.dismiss()
        } catch {
            self.saveErrorMessage = error.localizedDescription
        }
    }
}
