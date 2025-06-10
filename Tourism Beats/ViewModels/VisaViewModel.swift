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
        fetchRequirement()
    }

    func fetchRequirement() {
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                requirement = try await service.fetchVisaRequirement(
                    passport: passportCode,
                    destination: destinationCode
                )
            } catch {
                errorMessage = "Could not load visa requirements."
            }
            isLoading = false
        }
    }

    func updatePassport(to newCode: String) {
        passportCode = newCode
        fetchRequirement()
    }

    var summaryText: String {
        if passportCode.uppercased() == destinationCode.uppercased() {
            return "Welcome Home 🏡"
        }
        return requirement?.requirement ?? ""
    }

    var requirementColor: Color {
        if passportCode.uppercased() == destinationCode.uppercased() {
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
