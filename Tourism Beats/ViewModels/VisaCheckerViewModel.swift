//
//  VisaCheckerViewModel.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation
import Combine

class VisaCheckerViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var suggestedCountries: [CountryModel] = []
    @Published var selectedCountry: CountryModel?
    @Published var visaFreeResult: String?
    @Published var isLoading: Bool = false
    
    private let allCountries: [CountryModel]
    private let visaService: VisaServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    let city: CityModel
    
    init(city: CityModel, visaService: VisaServiceProtocol = VisaService(), countryDataService: CountryDataServiceProtocol = CountryDataService()) {
        self.city = city
        self.visaService = visaService
        self.allCountries = countryDataService.fetchAllCountries()
        setupBindings()
    }
    
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { [weak self] (text) -> [CountryModel] in
                guard let self = self else { return [] }
                return self.allCountries.filter {
                    $0.name.lowercased().contains(text.lowercased())
                }
            }
            .assign(to: \.suggestedCountries, on: self)
            .store(in: &cancellables)
    }
    
    func selectCountry(_ country: CountryModel) {
        selectedCountry = country
        searchText = country.name
        suggestedCountries = []
        Task {
            await checkVisaFreeTravel()
        }
    }
    
    @MainActor
    func checkVisaFreeTravel() async {
        guard let fromCountryCode = selectedCountry?.code else {
            visaFreeResult = "Unrecognized Country"
            return
        }
        let toCountryCode = city.country.code
        
        isLoading = true
        visaFreeResult = nil
        
        do {
            let visaFree = try await visaService.checkVisaFreeTravel(fromCountryCode: fromCountryCode, toCountryCode: toCountryCode)
            visaFreeResult = visaFree ? "YES" : "NO"
        } catch {
            visaFreeResult = "Error: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
