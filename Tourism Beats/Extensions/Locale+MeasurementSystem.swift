import Foundation

extension Locale {
    /// True for Metric & U.K., false for U.S.
    /// Uses the modern API when available; falls back to a fast, allocation-light check.
    var prefersCelsius: Bool {
        if #available(iOS 16, *) {
            switch self.measurementSystem {
            case .us: return false
            default: return true
            }
        } else {
            // Older OS fallback: avoid regex; strip non-letters cheaply.
            let scalars =
                (self as NSLocale)
                .object(forKey: NSLocale.Key.measurementSystem) as? String ?? ""
            var letters = String.UnicodeScalarView()
            letters.reserveCapacity(scalars.count)
            for s in scalars.unicodeScalars
            where CharacterSet.letters.contains(s)
            {
                letters.append(s)
            }
            return String(letters).uppercased() != "US"
        }
    }
}
