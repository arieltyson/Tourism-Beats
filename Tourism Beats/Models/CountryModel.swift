import Foundation

struct CountryModel: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String
}
