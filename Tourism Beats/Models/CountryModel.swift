struct CountryModel: Identifiable, Codable, Equatable, Hashable {
    let name: String
    let code: String
    let flag: String
    var id: String { code }
}
