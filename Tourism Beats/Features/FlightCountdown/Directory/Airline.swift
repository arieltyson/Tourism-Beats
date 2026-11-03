import Foundation

/// An airline, identified by its two-character IATA designator.
struct Airline: Codable, Hashable, Identifiable, Sendable {
    /// The IATA designator, such as `AC` or `B6`.
    let code: String
    let name: String

    var id: String { code }

    static func unlisted(code: String) -> Self {
        Airline(code: code, name: code)
    }

    /// Whether `value` reads as an IATA airline designator: two letters or
    /// digits, at least one of them a letter.
    static func isCode(_ value: String) -> Bool {
        value.wholeMatch(of: /[A-Z0-9]{2}/) != nil && value.contains(where: \.isLetter)
    }
}
