import SwiftUI

/// A flight's countdown as a card, exactly as its widget shows it.
struct FlightCountdownCard: View {
    let flight: CountdownFlight
    let date: Date
    var photos: [FlightCardImage] = []

    @ScaledMetric private var minimumHeight = FlightCountdownTokens.cardMinimumHeight

    var body: some View {
        FlightCountdownFace(flight: flight, date: date)
            .padding(SpacingTokens.large)
            .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .leading)
            .background {
                FlightCardBackground(theme: flight.cardTheme, photo: FlightPhotoRotation.photo(from: photos, of: flight, at: date))
            }
            .clipShape(.rect(cornerRadius: FlightCountdownTokens.cardCornerRadius))
    }
}
