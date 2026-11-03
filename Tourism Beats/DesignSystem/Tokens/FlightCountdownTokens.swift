import SwiftUI

/// Sizes and timings for Flight Countdown's screens, so its card, rows,
/// and pickers stay in proportion with each other.
enum FlightCountdownTokens {
    /// How long typing pauses before an airport search runs.
    static let searchDebounce: Duration = .milliseconds(150)

    /// The most digits an airline uses for a flight number.
    static let maximumFlightNumberLength = 4

    // MARK: - Card

    static let cardCornerRadius: CGFloat = 28
    /// A card's design shown small beside its flight in the list.
    static let thumbnailCornerRadius: CGFloat = 10
    /// Scaled with Dynamic Type so the card keeps a widget's proportions.
    static let cardMinimumHeight: CGFloat = 200
    /// A background choice, at least as large as the smallest tap target.
    static let swatchSize: CGFloat = 44
    /// The ring around the chosen background and the gap inside it.
    static let swatchRingWidth: CGFloat = 2
    static let swatchRingInset: CGFloat = 4

    /// The route drawing on the empty screen, scaled with Dynamic Type.
    static let emptyGlyphHeight: CGFloat = 64

    // MARK: - Widget Preview

    /// A small widget's side and shape on current iPhones.
    static let smallWidgetSide: CGFloat = 170
    static let widgetPreviewCornerRadius: CGFloat = 22
    static let widgetPreviewPadding: CGFloat = 16
    static let widgetPreviewMaximumTypeSize: DynamicTypeSize = .xxLarge

    // MARK: - Photos

    /// The longer side of a stored card photo, enough for the largest widget.
    static let photoPixelSize = 1_200
    static let photoCompressionQuality: Double = 0.8
}
