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

// MARK: - TripSuggestionsList

private struct TripSuggestionsList: View {
    let viewModel: TripSuggestionsViewModel
    let days: [TripSuggestionsViewModel.DaySuggestions]

    var body: some View {
        List {
            Section {
                Text(
                    "Top sights and restaurants from the \(self.viewModel.city.name) guide, "
                        + "grouped so each day stays in one area. Uncheck anything you'd rather skip. "
                        + "You can edit or remove activities later."
                )
                .font(TypographyTokens.cardLabel)
                .foregroundStyle(.secondary)
            }

            ForEach(self.days) { entry in
                Section {
                    ForEach(entry.suggestions) { suggestion in
                        TripSuggestionRow(
                            suggestion: suggestion,
                            isSelected: self.viewModel.isSelected(suggestion),
                            onToggle: {
                                self.viewModel.toggle(suggestion)
                            }
                        )
                    }
                } header: {
                    TripSuggestionDayHeader(day: entry.day)
                }
            }

            Section {
                EmptyView()
            } footer: {
                VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                    if let coverageNote = self.viewModel.coverageNote {
                        Text(coverageNote)
                    }

                    if let sourcesLabel = self.sourcesLabel {
                        Text(sourcesLabel)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var sourcesLabel: String? {
        var seenSourceNames = Set<String>()
        let uniqueSourceNames = self.days
            .flatMap { $0.suggestions.map(\.sourceName) }
            .filter { !$0.isEmpty && seenSourceNames.insert($0).inserted }
        guard !uniqueSourceNames.isEmpty else { return nil }
        return "Sources: \(uniqueSourceNames.formatted(.list(type: .and)))."
    }
}

// MARK: - TripSuggestionDayHeader

private struct TripSuggestionDayHeader: View {
    let day: TripDay

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.day.displayLabel)

            if let subtitle = self.subtitle {
                Text(subtitle)
                    .textCase(nil)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// The day number (when a custom label replaces it) and the date.
    private var subtitle: String? {
        let dayNumberLabel = "Day \(self.day.dayNumber.formatted(.number))"
        let parts = [
            self.day.displayLabel == dayNumberLabel ? nil : dayNumberLabel,
            self.day.dateLabel
        ]
        .compactMap(\.self)

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

// MARK: - TripSuggestionRow

private struct TripSuggestionRow: View {
    let suggestion: TripActivitySuggestion
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button {
            self.onToggle()
        } label: {
            HStack(alignment: .top, spacing: SpacingTokens.small) {
                Image(systemName: self.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(self.isSelected ? AppColors.coral : .secondary)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    HStack(spacing: SpacingTokens.xSmall) {
                        Label(
                            self.suggestion.type.label,
                            systemImage: self.suggestion.type.systemImage
                        )
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(self.suggestion.type.color)

                        Text("\(self.suggestion.slot.label) · \(self.timeLabel)")
                            .font(TypographyTokens.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Text(self.suggestion.name)
                        .font(TypographyTokens.cardLabel)
                        .bold()
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    if let location = self.suggestion.location {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if let notes = self.suggestion.notes {
                        Text(notes)
                            .font(TypographyTokens.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(self.isSelected ? .isSelected : [])
        .accessibilityHint(self.isSelected ? "Removes it from the plan" : "Adds it to the plan")
    }

    private var timeLabel: String {
        let time = Calendar.current.date(
            bySettingHour: self.suggestion.slot.hour,
            minute: self.suggestion.slot.minute,
            second: 0,
            of: .now
        ) ?? .now
        return time.formatted(date: .omitted, time: .shortened)
    }
}

// MARK: - TripSuggestionPromptCard

/// Offers a suggested plan when a trip has no activities yet.
struct TripSuggestionPromptCard: View {
    let trip: Trip
    let onSuggest: () -> Void

    var body: some View {
        GlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Label("Start With a Suggested Plan", systemImage: "sparkles")
                    .font(TypographyTokens.sectionHeader)
                    .bold()
                    .foregroundStyle(AppColors.gold)

                Text(self.message)
                    .font(TypographyTokens.body)
                    .foregroundStyle(.secondary)

                Button("Suggest a Plan", systemImage: "sparkles") {
                    self.onSuggest()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.coral)
            }
        }
    }

    private var message: String {
        let dayLabel = self.trip.dayCount == 1
            ? "your day"
            : "all \(self.trip.dayCount.formatted(.number)) days"
        return "Fill \(dayLabel) with top sights and restaurants in \(self.trip.city), "
            + "grouped by area. You review everything before it's added."
    }
}
