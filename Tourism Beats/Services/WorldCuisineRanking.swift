import Foundation

// MARK: - WorldCuisineRanking

/// The world's five best-rated cuisines in TasteAtlas's 2025/26 awards,
/// ranked from hundreds of thousands of diners' ratings of dishes.
///
/// Bundled with the app rather than fetched, so it costs nothing and
/// works offline. Update it when a new edition is published.
enum WorldCuisineRanking {
    static let source = String(localized: "TasteAtlas Awards 25/26")

    static let top: [WorldCuisine] = [
        WorldCuisine(
            rank: 1, name: String(localized: "Italian"), flag: "🇮🇹",
            signatureDish: String(localized: "Pizza napoletana"),
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Neapolitan_pizza_at_Trappica_%2848701940197%29.jpg/1280px-Neapolitan_pizza_at_Trappica_%2848701940197%29.jpg")
        ),
        WorldCuisine(
            rank: 2, name: String(localized: "Greek"), flag: "🇬🇷",
            signatureDish: String(localized: "Moussaka"),
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/MussakasMeMelitsanesKePatates01.JPG/1280px-MussakasMeMelitsanesKePatates01.JPG")
        ),
        WorldCuisine(
            rank: 3, name: String(localized: "Peruvian"), flag: "🇵🇪",
            signatureDish: String(localized: "Ceviche"),
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/78/Cebiche_de_corvina.JPG/1280px-Cebiche_de_corvina.JPG")
        ),
        WorldCuisine(
            rank: 4, name: String(localized: "Portuguese"), flag: "🇵🇹",
            signatureDish: String(localized: "Pastel de nata"),
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Pasteis_de_Belem.jpg/1280px-Pasteis_de_Belem.jpg")
        ),
        WorldCuisine(
            rank: 5, name: String(localized: "Spanish"), flag: "🇪🇸",
            signatureDish: String(localized: "Paella"),
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/01_Paella_Valenciana_original.jpg/1280px-01_Paella_Valenciana_original.jpg")
        ),
    ]
}
