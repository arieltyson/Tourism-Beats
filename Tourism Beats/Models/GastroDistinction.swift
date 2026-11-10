import Foundation

// MARK: - GastroDistinction

/// The one fact that earns a city its place among the gastronomic capitals,
/// told in a few words beside a symbol for the kind of fact it is.
struct GastroDistinction: Hashable, Sendable {
    let text: String
    let systemImage: String

    /// Michelin-starred restaurants inside the city, from its 2026 guide.
    static func michelinStarred(_ count: Int) -> GastroDistinction {
        GastroDistinction(
            text: String(localized: "\(count) Michelin-starred restaurants"),
            systemImage: "star.fill"
        )
    }

    /// A floor rather than a count, where the guides' city lines and
    /// published tallies differ by a few restaurants.
    static func michelinStarred(atLeast count: Int) -> GastroDistinction {
        GastroDistinction(
            text: String(localized: "\(count)+ Michelin-starred restaurants"),
            systemImage: "star.fill"
        )
    }

    /// Restaurants the city places on The World's 50 Best Restaurants 2026.
    static func worldsFiftyBest(_ count: Int) -> GastroDistinction {
        GastroDistinction(
            text: String(localized: "\(count) of the World’s 50 Best"),
            systemImage: "medal.fill"
        )
    }

    /// The city's highest place on The World's 50 Best Restaurants 2026.
    static func worldsFiftyBest(rank: Int) -> GastroDistinction {
        GastroDistinction(
            text: String(localized: "No. \(rank) of the World’s 50 Best"),
            systemImage: "medal.fill"
        )
    }

    /// A star-count fact that isn't a plain tally, such as density.
    static func michelin(_ text: String) -> GastroDistinction {
        GastroDistinction(text: text, systemImage: "star.fill")
    }

    /// Recognition beyond restaurant guides, such as a world chef
    /// competition.
    static func honour(_ text: String) -> GastroDistinction {
        GastroDistinction(text: text, systemImage: "trophy.fill")
    }

    /// A food culture UNESCO lists as intangible cultural heritage.
    static func heritage(_ text: String) -> GastroDistinction {
        GastroDistinction(text: text, systemImage: "building.columns.fill")
    }
}
