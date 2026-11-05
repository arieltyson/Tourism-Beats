import SwiftUI

// MARK: - TripStaySearchResultRow

struct TripStaySearchResultRow: View {
    let stay: TripStay

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text(self.stay.name)
                .foregroundStyle(Color.primary)
            if let address = self.stay.address {
                Text(address)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Uses this hotel for the trip")
    }
}
