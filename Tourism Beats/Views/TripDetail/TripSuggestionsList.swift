import SwiftUI

// MARK: - TripSuggestionsList

struct TripSuggestionsList: View {
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
