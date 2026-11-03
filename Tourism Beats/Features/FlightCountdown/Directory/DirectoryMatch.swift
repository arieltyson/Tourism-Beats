import Foundation

/// How closely a directory entry matches a search, best first.
enum DirectoryMatch: Int, Comparable, Sendable {
    case code
    case prefix
    case wordPrefix
    case contains

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Ranks `text` against `query`, ignoring case and diacritics, so
    /// "montreal" finds "Montréal".
    static func rank(_ text: String, for query: String) -> Self? {
        guard let range = text.localizedStandardRange(of: query) else { return nil }
        if range.lowerBound == text.startIndex { return .prefix }
        let words = text.split { !$0.isLetter && !$0.isNumber }
        if words.contains(where: { $0.localizedStandardRange(of: query)?.lowerBound == $0.startIndex }) {
            return .wordPrefix
        }
        return .contains
    }

    /// The query as a person typed it, trimmed and ready to compare with codes.
    static func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
