import Foundation

extension CityActivity {
    var hasGenericFallbackSummary: Bool {
        let normalizedSummary = self.summary.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        let isLegacyFallback = normalizedSummary.localizedStandardContains("notable")
            && normalizedSummary.localizedStandardContains("worth visiting")

        let isAppleMapsFallback = normalizedSummary.localizedStandardContains("apple maps")
            && (
                normalizedSummary.localizedStandardContains("surfaced consistently")
                    || normalizedSummary.localizedStandardContains("discovery results")
                    || normalizedSummary.localizedStandardContains("high-demand attraction")
            )

        return isLegacyFallback || isAppleMapsFallback
    }
}
