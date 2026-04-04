import Foundation

extension CityActivity {
    var hasGenericFallbackSummary: Bool {
        let normalizedSummary = self.summary.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        let isLegacyFallback = normalizedSummary.localizedStandardContains("notable")
            && normalizedSummary.localizedStandardContains("worth visiting")

        let isLegacyAppleMapsFallback = normalizedSummary.localizedStandardContains("apple maps")
            && (
                normalizedSummary.localizedStandardContains("surfaced consistently")
                    || normalizedSummary.localizedStandardContains("discovery results")
                    || normalizedSummary.localizedStandardContains("high-demand attraction")
            )

        let isGeneratedAppleMapsFallback = self.sourceName == "Apple Maps"
            && (
                normalizedSummary.localizedStandardContains("top-rated attraction searches for the city")
                    || normalizedSummary.localizedStandardContains("popular attraction searches for the city")
                    || normalizedSummary.localizedStandardContains("stronger attraction matches for the city")
                    || normalizedSummary.localizedStandardContains("useful visitor stop for the city")
            )

        return isLegacyFallback || isLegacyAppleMapsFallback || isGeneratedAppleMapsFallback
    }
}
