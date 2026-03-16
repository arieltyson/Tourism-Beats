import Foundation

struct CityFunFact: Equatable, Sendable {
    let text: String
    let sourceName: String
    let sourceURL: URL?
    let isFallback: Bool
}
