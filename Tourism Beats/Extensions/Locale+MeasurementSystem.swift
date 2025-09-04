import Foundation

extension Locale {
    /// Returns the raw “measurementSystem” value from NSLocale,
    /// e.g. "Metric", "U.S.", or "U.K."
    private var rawMeasurementSystem: String {
        (self as NSLocale)
            .object(forKey: NSLocale.Key.measurementSystem) as? String
            ?? ""
    }

    /// True for Metric & U.K., false for U.S.
    var prefersCelsius: Bool {
        // Strip out punctuation (so “U.S.” → “US”) and uppercase
        let lettersOnly =
            self.rawMeasurementSystem
                .replacingOccurrences(
                    of: "\\P{L}",
                    with: "",
                    options: .regularExpression
                )
                .uppercased()
        return lettersOnly != "US"
    }
}
