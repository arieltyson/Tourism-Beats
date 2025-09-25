struct CountryModel: Identifiable, Codable, Equatable, Hashable, Sendable {
    let name: String
    let code: String
    let flag: String
    var id: String { self.code }
}
