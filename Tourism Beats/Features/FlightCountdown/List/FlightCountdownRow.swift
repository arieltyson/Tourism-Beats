import CoreGraphics
import SwiftUI

/// A flight in the list: its card design, route, and when it leaves.
struct FlightCountdownRow: View {
    let flight: CountdownFlight
    var photo: CGImage?
    let now: Date

    @ScaledMetric private var thumbnailSize = FlightCountdownTokens.swatchSize

    var body: some View {
        HStack(spacing: SpacingTokens.small) {
            FlightCardBackground(theme: flight.cardTheme, photo: photo)
                .frame(width: thumbnailSize, height: thumbnailSize)
                .clipShape(.rect(cornerRadius: FlightCountdownTokens.thumbnailCornerRadius))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                Text("\(flight.originName) → \(flight.destinationName)")
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        // Inside a button, `.primary` would resolve to the tint colour.
        .foregroundStyle(Color.primary)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        var format = Date.FormatStyle(date: .abbreviated, time: .shortened)
        format.timeZone = flight.timeZone
        let day = flight.departure.formatted(format)
        return flight.departure > now
            ? "\(flight.spokenName) · \(day)"
            : String(localized: "Departed \(day)")
    }
}
