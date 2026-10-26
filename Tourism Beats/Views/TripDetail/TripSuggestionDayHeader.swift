import SwiftUI

// MARK: - TripSuggestionDayHeader

struct TripSuggestionDayHeader: View {
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
