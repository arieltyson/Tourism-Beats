import SwiftUI

// MARK: - TripDayHeaderTitle

struct TripDayHeaderTitle: View {
    let day: TripDay

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text(self.day.displayLabel)
                .font(TypographyTokens.sectionHeader)
                .bold()

            if let dateLabel = self.day.dateLabel {
                Text(dateLabel)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
