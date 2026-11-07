import SwiftUI

// MARK: - AdvisoriesDensity

/// How tightly the advisories page sets its cards.
///
/// The page fits the screen rather than scrolling inside the city pager.
/// Where the regular layout runs long, the compact one draws the cards
/// closer and drops the sentences that only expand on each walkability
/// rating, so every fact still shows on smaller iPhones.
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

    /// Whether the walkability tiles explain their ratings in a sentence.
    var showsWalkabilityDetail: Bool {
        self == .regular
    }
}

extension EnvironmentValues {
    /// How tightly the advisories page sets its cards.
    @Entry var advisoriesDensity = AdvisoriesDensity.regular
}
