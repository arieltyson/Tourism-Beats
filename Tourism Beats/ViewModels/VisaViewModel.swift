import Observation
import SwiftUI

@MainActor
@Observable
final class VisaViewModel {
    private(set) var requirement: VisaModel?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var passportCode: String

    @ObservationIgnored private let destinationCode: String
    @ObservationIgnored private let service: VisaProtocol

    init(
        passportCode: String,
        destinationCode: String,
        service: VisaProtocol = VisaService()
    ) {
        self.passportCode = passportCode
        self.destinationCode = destinationCode
        self.service = service
    }

    func fetchRequirement() async {
        self.isLoading = true
        self.errorMessage = nil

        do {
            self.requirement = try await self.service.fetchVisaRequirement(
                passport: self.passportCode,
                destination: self.destinationCode
            )
        } catch {
            self.errorMessage = "Could not load visa requirements."
        }

        self.isLoading = false
    }

    func updatePassport(to newCode: String) {
        self.passportCode = newCode
        Task {
            await self.fetchRequirement()
        }
    }

    var summaryText: String {
        if self.passportCode.uppercased() == self.destinationCode.uppercased() {
            return "Welcome Home 🏡"
        }
        return self.requirement?.requirement ?? ""
    }

    var requirementColor: Color {
        if self.passportCode.uppercased() == self.destinationCode.uppercased() {
            return .green
        }
        guard let req = self.requirement?.requirement.lowercased() else {
            return .gray
        }
        if req.localizedStandardContains("visa required") {
            return .orange
        } else if req.localizedStandardContains("visa-on-arrival") {
            return .yellow
        } else if req.localizedStandardContains("eta") {
            return .purple
        } else if req.localizedStandardContains("visa-free") {
            return .green
        } else {
            return .gray
        }
    }
}
