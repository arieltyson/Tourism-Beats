import CoreGraphics
import Testing
@testable import Tourism_Beats

// MARK: - AdvisoriesDensityTests

struct AdvisoriesDensityTests {
    @Test(arguments: [
        (nil, 700.0, AdvisoriesDensity.regular),
        (650.0, 700.0, .regular),
        (700.0, 700.0, .regular),
        (760.0, 700.0, .compact),
        (760.0, 0.0, .regular)
    ] as [(CGFloat?, CGFloat, AdvisoriesDensity)])
    func cardsDrawCloserOnlyWhereTheRegularLayoutRunsLong(
        regularContentHeight: CGFloat?,
        pageHeight: CGFloat,
        expected: AdvisoriesDensity
    ) {
        #expect(AdvisoriesDensity.fitting(regularContentHeight: regularContentHeight, in: pageHeight) == expected)
    }
}
