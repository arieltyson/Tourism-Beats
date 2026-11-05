import SwiftUI

/// A flight in the list: its card design, route, and when it leaves.
struct FlightCountdownRow: View {
    let flight: CountdownFlight
    var photos: [FlightCardImage] = []
    let now: Date

    @ScaledMetric private var thumbnailSize = FlightCountdownTokens.swatchSize

    var body: some View {
        HStack(spacing: SpacingTokens.small) {
            FlightCardBackground(theme: flight.cardTheme, photo: FlightPhotoRotation.photo(from: photos, of: flight, at: now))
                .frame(width: thumbnailSize, height: thumbnailSize)
                .clipShape(.rect(cornerRadius: FlightCountdownTokens.thumbnailCornerRadius))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                Text("\(flight.originName) → \(flight.destinationName)")
                    .font(.headline)
                FlightCountdownRowSubtitle(flight: flight, now: now)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        // Inside a button, `.primary` would resolve to the tint colour.
        .foregroundStyle(Color.primary)
        .accessibilityElement(children: .combine)
    }
}
