import SwiftUI

// MARK: - AdvisoriesDensity

/// How tightly the advisories page sets its cards.
///
/// The page fits the screen rather than scrolling inside the city pager.
/// Where the regular layout runs long, the compact one draws the cards
/// closer and drops the sentences that only expand on each walkability
/// rating, so every fact still shows on smaller iPhones. Only where even that
/// overflows, at large text sizes, does the page scroll.
enum AdvisoriesDensity {
    case regular
    case compact

    /// The space between the cards.
    var cardSpacing: CGFloat {
        switch self {
        case .regular: SpacingTokens.small
        case .compact: SpacingTokens.xSmall
        }
    }

    /// The space between each card's edge and its content.
    var cardPadding: CGFloat {
        switch self {
        case .regular: SpacingTokens.small
        case .compact: SpacingTokens.xSmall
        }
    }

    /// The space between the rows inside a card.
    var cardContentSpacing: CGFloat {
        switch self {
        case .regular: SpacingTokens.small
        case .compact: SpacingTokens.xSmall
        }
    }

    /// The density for a page `pageHeight` tall, given how tall its cards
    /// are at the regular density: regular where they fit or haven't been
    /// measured yet, and compact where they run long.
    static func fitting(regularContentHeight: CGFloat?, in pageHeight: CGFloat) -> AdvisoriesDensity {
        guard let regularContentHeight, pageHeight > 0 else { return .regular }
        return regularContentHeight > pageHeight ? .compact : .regular
    }

    /// Whether the walkability tiles explain their ratings in a sentence.
    var showsWalkabilityDetail: Bool {
        self == .regular
    }
}

extension EnvironmentValues {
    /// How tightly the advisories page sets its cards.
    @Entry var advisoriesDensity = AdvisoriesDensity.regular
}
