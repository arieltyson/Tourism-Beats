//
//  SafetyAdvisoryViewModel.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation

@MainActor
class SafetyAdvisoryViewModel: ObservableObject {
    @Published var safetyData: SafetyDataModel?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    let city: CityModel
    private let safetyService: SafetyServiceProtocol

    init(city: CityModel, safetyService: SafetyServiceProtocol = SafetyService()) {
        self.city = city
        self.safetyService = safetyService
        fetchSafetyData()
    }

    func fetchSafetyData() {
        isLoading = true
        errorMessage = nil

        let countryCode = city.country.code
        print("Fetching safety data for country code: \(countryCode)")

        Task {
            do {
                let data = try await safetyService.fetchSafetyData(for: countryCode)
                self.safetyData = data
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}
