import SwiftUI

@MainActor
class VisaViewModel: ObservableObject {
    @Published var requirement: VisaModel?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var passportCode: String
    let destinationCode: String
    private let service: VisaProtocol

    init(
        passportCode: String,
        destinationCode: String,
        service: VisaProtocol = VisaService()
    ) {
        self.passportCode = passportCode
        self.destinationCode = destinationCode
        self.service = service
        self.fetchRequirement()
    }

    func fetchRequirement() {
        self.isLoading = true
        self.errorMessage = nil

        Task { @MainActor in
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
    }

    func updatePassport(to newCode: String) {
        self.passportCode = newCode
        self.fetchRequirement()
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
        guard let req = requirement?.requirement.lowercased() else {
            return .gray
        }
        if req.contains("banned") {
            return .red
        } else if req.contains("visa required") {
            return .orange
        } else if req.contains("visa-on-arrival") {
            return .yellow
        } else if req.contains("eta") {
            return .purple
        } else if req.contains("visa-free") {
            return .green
        } else {
            return .gray
        }
    }
}
