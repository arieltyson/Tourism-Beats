//
//  CityData.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation

struct CityData {
    static func cities(countryDataService: CountryDataServiceProtocol) -> [CityModel] {
        let service = countryDataService
        return [
            CityModel(name: "London", country: service.getCountryByName("United Kingdom") ?? CountryModel(name: "United Kingdom", code: "GB", flag: "🇬🇧"), imageName: "big_ben_image"),
            CityModel(name: "Paris", country: service.getCountryByName("France") ?? CountryModel(name: "France", code: "FR", flag: "🇫🇷"), imageName: "eiffel_tower_image"),
            CityModel(name: "Tokyo", country: service.getCountryByName("Japan") ?? CountryModel(name: "Japan", code: "JP", flag: "🇯🇵"), imageName: "tokyo_tower_image"),
            CityModel(name: "Berlin", country: service.getCountryByName("Germany") ?? CountryModel(name: "Germany", code: "DE", flag: "🇩🇪"), imageName: "brandenburg_gate_image"),
            CityModel(name: "Barcelona", country: service.getCountryByName("Spain") ?? CountryModel(name: "Spain", code: "ES", flag: "🇪🇸"), imageName: "sagrada_familia_image"),
            CityModel(name: "Rome", country: service.getCountryByName("Italy") ?? CountryModel(name: "Italy", code: "IT", flag: "🇮🇹"), imageName: "colosseum_image"),
            CityModel(name: "Beijing", country: service.getCountryByName("China") ?? CountryModel(name: "China", code: "CN", flag: "🇨🇳"), imageName: "great_wall_of_china_image"),
            CityModel(name: "Cairo", country: service.getCountryByName("Egypt") ?? CountryModel(name: "Egypt", code: "EG", flag: "🇪🇬"), imageName: "great_pyramid_of_giza_image"),
            CityModel(name: "New Delhi", country: service.getCountryByName("India") ?? CountryModel(name: "India", code: "IN", flag: "🇮🇳"), imageName: "india_gate_image"),
            CityModel(name: "Rio De Janeiro", country: service.getCountryByName("Brazil") ?? CountryModel(name: "Brazil", code: "BR", flag: "🇧🇷"), imageName: "christ_the_redeemer_image"),
            CityModel(name: "Moscow", country: service.getCountryByName("Russia") ?? CountryModel(name: "Russia", code: "RU", flag: "🇷🇺"), imageName: "kremlin_image"),
            CityModel(name: "Amsterdam", country: service.getCountryByName("Netherlands") ?? CountryModel(name: "Netherlands", code: "NL", flag: "🇳🇱"), imageName: "van_gogh_museum_image"),
            CityModel(name: "Athens", country: service.getCountryByName("Greece") ?? CountryModel(name: "Greece", code: "GR", flag: "🇬🇷"), imageName: "the_acropolis_image"),
            CityModel(name: "Bangkok", country: service.getCountryByName("Thailand") ?? CountryModel(name: "Thailand", code: "TH", flag: "🇹🇭"), imageName: "grand_palace_image")
        ]
    }
}
