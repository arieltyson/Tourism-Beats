import CoreGraphics
import SwiftUI

/// One background a card can have, ringed when it's the chosen one.
struct FlightThemeSwatch: View {
    let theme: FlightCardTheme
    var photo: CGImage?
    let isSelected: Bool
    let action: () -> Void

    @ScaledMetric private var size = FlightCountdownTokens.swatchSize

    var body: some View {
        Button(action: action) {
            FlightCardBackground(theme: theme, photo: photo)
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
