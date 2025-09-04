import Foundation

struct VisaModel: Codable, Identifiable, Sendable {
    var id: String { "\(self.passport)-\(self.destination)" }

    let passport: String
    let destination: String
    let requirement: String
}
