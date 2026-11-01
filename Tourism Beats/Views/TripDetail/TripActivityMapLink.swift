import SwiftUI

// MARK: - TripActivityMapLink

/// Where an activity happens, opening it in Google Maps.
struct TripActivityMapLink: View {
    let location: String?
    let url: URL

    var body: some View {
        Link(destination: self.url) {
            Label(self.title, systemImage: "mappin.and.ellipse")
                .font(TypographyTokens.caption)
                .multilineTextAlignment(.leading)
        }
        .tint(AppColors.info)
        .accessibilityHint("Opens in Google Maps")
    }

    private var title: String {
        guard let location, !location.isEmpty else { return "Show on Map" }
        return location
    }
}
