import Foundation

// MARK: - GastroCityRanking

/// The world's fifteen gastronomic capitals, ranked on four kinds of
/// evidence:
///
/// 1. **Michelin depth:** starred restaurants inside the city in its 2026
///    MICHELIN Guide (Tokyo 160, Paris 127, Kyoto ~97, London ~84,
///    Osaka ~81, Hong Kong 77, New York ~62, Seoul ~41, Bangkok ~39).
/// 2. **Michelin density:** starred restaurants per resident. Kyoto leads
///    cities of over 500,000 (1 per 14,637; Chef's Pencil, 2024). San
///    Sebastián, with about 190,000 people, holds two three-star
///    restaurants (Arzak, Akelarre), with a third (Martín Berasategui)
///    just outside it.
/// 3. **The World's 50 Best Restaurants 2026:** Bangkok places five,
///    Copenhagen and Lima three each, and Mexico City's Quintonil is No. 4.
///    Lima's Central and Maido, and Copenhagen's Noma and Geranium, are
///    past No. 1s now in the list's Best of the Best.
/// 4. **Culinary heritage:** Lyon was named the world capital of
///    gastronomy by the critic Curnonsky in 1935 and has hosted the
///    Bocuse d'Or, the world chef championship, since 1987. UNESCO lists
///    washoku, the French gastronomic meal, Mexican cuisine, and
///    Singapore's hawker culture as intangible cultural heritage.
///
/// Each city shows the one fact that best earns its place. Where sources
/// disagree on a count by a few restaurants, the card states a floor.
///
/// Bundled with the app rather than fetched, so it costs nothing and
/// works offline. Revisit it when the guides and the 50 Best publish anew.
enum GastroCityRanking {
    static let source = String(localized: "MICHELIN Guide & World’s 50 Best 2026")

    static let methodology = String(
        localized: """
        Ranked by Michelin-starred restaurants, how many and how close together, \
        by places on The World’s 50 Best Restaurants 2026, \
        and by culinary heritage honoured by UNESCO and the Bocuse d’Or.
        """
    )

    static let top: [GastroCity] = [
        GastroCity(rank: 1, name: "Tokyo", countryCode: "JP", distinction: .michelinStarred(160)),
        GastroCity(rank: 2, name: "Paris", countryCode: "FR", distinction: .michelinStarred(127)),
        GastroCity(
            rank: 3, name: "Kyoto", countryCode: "JP",
            distinction: .michelin(String(localized: "Most starred restaurants per resident"))
        ),
        GastroCity(rank: 4, name: "Osaka", countryCode: "JP", distinction: .michelinStarred(atLeast: 80)),
        GastroCity(rank: 5, name: "Hong Kong", countryCode: "HK", distinction: .michelinStarred(77)),
        GastroCity(
            rank: 6, name: "San Sebastián", countryCode: "ES",
            distinction: .michelin(String(localized: "Two three-star tables, one small city"))
        ),
        GastroCity(
            rank: 7, name: "Lyon", countryCode: "FR",
            distinction: .honour(String(localized: "Home of the Bocuse d’Or"))
        ),
        GastroCity(rank: 8, name: "Bangkok", countryCode: "TH", distinction: .worldsFiftyBest(5)),
        GastroCity(rank: 9, name: "London", countryCode: "GB", distinction: .michelinStarred(atLeast: 80)),
        GastroCity(rank: 10, name: "New York", countryCode: "US", distinction: .michelinStarred(atLeast: 60)),
        GastroCity(rank: 11, name: "Copenhagen", countryCode: "DK", distinction: .worldsFiftyBest(3)),
        GastroCity(rank: 12, name: "Lima", countryCode: "PE", distinction: .worldsFiftyBest(3)),
        GastroCity(
            rank: 13, name: "Singapore", countryCode: "SG",
            distinction: .heritage(String(localized: "Hawker culture, UNESCO heritage"))
        ),
        GastroCity(rank: 14, name: "Seoul", countryCode: "KR", distinction: .michelinStarred(atLeast: 40)),
        GastroCity(rank: 15, name: "Mexico City", countryCode: "MX", distinction: .worldsFiftyBest(rank: 4))
    ]
}
