// MARK: - WalkabilityModel+Placeholder

extension WalkabilityModel {
    /// Scores shown, redacted, while the real ones load. Their ratings have
    /// the longest descriptions, so the card never grows when the real
    /// scores arrive.
    static let placeholder = WalkabilityModel(
        city: "",
        administrativeArea: nil,
        countryCode: "",
        walkScore: 60,
        transitScore: 60
    )
}
