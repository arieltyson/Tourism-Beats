import CoreLocation
import Foundation

// MARK: - WikipediaArticleLocationVerifier

/// Decides whether a Wikipedia article describes a place in the city being
/// viewed. Articles are found by title, and many places share a name, so
/// nothing from an article is shown until it passes this check.
enum WikipediaArticleLocationVerifier {
    /// How far an article's coordinates may sit from a place with a known
    /// location. Generous enough for large sites like parks and old towns.
    static let maximumDistanceFromPlace: CLLocationDistance = 5_000

    /// How far an article's coordinates may sit from the city centre when the
    /// place's own location is unknown. Matches the reach of activity searches.
    static let maximumDistanceFromCity: CLLocationDistance = 35_000

    static func isArticle(_ summary: WikipediaSummary, about context: WikipediaLookupContext) -> Bool {
        if let articleLocation = summary.location {
            if let placeLocation = context.placeLocation {
                return articleLocation.distance(from: placeLocation) <= self.maximumDistanceFromPlace
            }
            return articleLocation.distance(from: context.cityLocation) <= self.maximumDistanceFromCity
        }

        // Without coordinates, the article has to name the city itself.
        return [summary.description, summary.extract].contains { text in
            text.map { self.text($0, mentions: context.cityName) } ?? false
        }
    }

    /// Whole-word match that ignores accents and punctuation but not case,
    /// since articles capitalize place names: "Nice" matches "in Nice, France"
    /// but not "a nice view", and "Cluj Napoca" matches "Cluj-Napoca".
    static func text(_ text: String, mentions name: String) -> Bool {
        let nameWords = self.words(in: name)
        guard !nameWords.isEmpty else { return false }

        let textWords = self.words(in: text)
        guard textWords.count >= nameWords.count else { return false }

        return (0 ... textWords.count - nameWords.count).contains { start in
            Array(textWords[start ..< start + nameWords.count]) == nameWords
        }
    }

    private static func words(in text: String) -> [String] {
        text.folding(options: .diacriticInsensitive, locale: .current)
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }
}
