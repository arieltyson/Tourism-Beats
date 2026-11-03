import SwiftUI

struct FlightCountdownHero: View {
    let flight: CountdownFlight
    let date: Date

    var body: some View {
        FlightCountdownFace(flight: flight, date: date)
            .padding(SpacingTokens.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                FlightCountdownBackdrop()
                    .clipShape(.rect(cornerRadius: SettingsLayoutTokens.sectionCornerRadius))
            }
    }
}
