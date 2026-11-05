/// A horizontal band of the card where one group of text sits, as
/// fractions of the card's height from the top.
struct FlightScrimBand: Sendable {
    let span: ClosedRange<Double>
    /// The least shade the band keeps even over a dark photo, so the card
    /// still has a gentle frame of shadow at its top and bottom.
    let minimumOpacity: Double
}
