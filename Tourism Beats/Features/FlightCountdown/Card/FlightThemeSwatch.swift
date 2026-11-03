import SwiftUI

/// One background a card can have, ringed when it's the chosen one.
struct FlightThemeSwatch: View {
    let theme: FlightCardTheme
    var photos: [FlightCardImage] = []
    let isSelected: Bool
    let action: () -> Void

    @ScaledMetric private var size = FlightCountdownTokens.swatchSize

    var body: some View {
        Button(action: action) {
            FlightCardBackground(theme: theme, photos: photos)
                .frame(width: size, height: size)
                .clipShape(.circle)
                .padding(FlightCountdownTokens.swatchRingInset)
                .overlay {
                    if isSelected {
                        Circle().strokeBorder(.tint, lineWidth: FlightCountdownTokens.swatchRingWidth)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(theme.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
