import Foundation

struct CountryModel: Identifiable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String
}
