import Foundation

struct VisaModel: Codable, Identifiable {
    var id: String { "\(passport)-\(destination)" }

    let passport: String
    let destination: String
    let requirement: String
}
