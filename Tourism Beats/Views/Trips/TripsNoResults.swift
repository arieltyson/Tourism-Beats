import SwiftUI

// MARK: - TripsNoResults

struct TripsNoResults: View {
    let searchText: String
    let selectedStatusFilter: TripStatus?

    var body: some View {
        VStack(spacing: SpacingTokens.medium) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text(self.message)
                .font(TypographyTokens.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingTokens.xLarge)
    }

    private var message: String {
        if let selectedStatusFilter, self.searchText.isEmpty {
            return "No \(selectedStatusFilter.label.lowercased()) trips yet."
        }

        if let selectedStatusFilter {
            return "No \(selectedStatusFilter.label.lowercased()) trips match \"\(self.searchText)\"."
        }

        return "No trips match \"\(self.searchText)\"."
    }
}
