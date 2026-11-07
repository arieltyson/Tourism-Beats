import Foundation

struct CityFunFact: Equatable, Sendable {
    let text: String
    /// Where a looked-up fact came from; `nil` for a curated fact.
    let sourceName: String?
    let sourceURL: URL?
    let isFallback: Bool
}

extension CityFunFact {
    /// A fact written into the catalog, told without a source.
    static func curated(_ text: String) -> CityFunFact {
        CityFunFact(text: text, sourceName: nil, sourceURL: nil, isFallback: false)
    }
}
