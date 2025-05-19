import SwiftUI

@MainActor
class VisaAdvisoryViewModel: ObservableObject {
    @Published var requirement: VisaModel?
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var passportCode: String
    let destinationCode: String

    private let service: VisaServiceProtocol

    init(
        passportCode: String,
        destinationCode: String,
        service: VisaServiceProtocol = VisaService()
    ) {
        self.passportCode = passportCode
        self.destinationCode = destinationCode
        self.service = service
        fetchRequirement()
    }

    func fetchRequirement() {
        isLoading = true
        errorMessage = nil
        Task {
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
        guard let r = requirement else { return "" }
        return r.requirement
    }
}
