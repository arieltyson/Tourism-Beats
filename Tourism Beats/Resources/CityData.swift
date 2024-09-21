//
//  CityData.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation
import MapKit

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
            CityModel(name: "Bangkok", country: service.getCountryByName("Thailand") ?? CountryModel(name: "Thailand", code: "TH", flag: "🇹🇭"), imageName: "grand_palace_image"),
            CityModel(name: "Lagos", country: service.getCountryByName("Nigeria") ?? CountryModel(name: "Nigeria", code: "NG", flag: "🇳🇬"), imageName: "lagos_image"),
            CityModel(name: "Cape Town", country: service.getCountryByName("South Africa") ?? CountryModel(name: "South Africa", code: "ZA", flag: "🇿🇦"), imageName: "cape_town_image"),
            CityModel(name: "Nairobi", country: service.getCountryByName("Kenya") ?? CountryModel(name: "Kenya", code: "KE", flag: "🇰🇪"), imageName: "nairobi_image"),
            CityModel(name: "Stockholm", country: service.getCountryByName("Sweden") ?? CountryModel(name: "Sweden", code: "SE", flag: "🇸🇪"), imageName: "stockholm_image"),
            CityModel(name: "Istanbul", country: service.getCountryByName("Turkey") ?? CountryModel(name: "Turkey", code: "TR", flag: "🇹🇷"), imageName: "istanbul_image"),
            CityModel(name: "Copenhagen", country: service.getCountryByName("Denmark") ?? CountryModel(name: "Denmark", code: "DK", flag: "🇩🇰"), imageName: "copenhagen_image"),
            CityModel(name: "Dubai", country: service.getCountryByName("United Arab Emirates") ?? CountryModel(name: "United Arab Emirates", code: "AE", flag: "🇦🇪"), imageName: "dubai_image"),
            CityModel(name: "Tehran", country: service.getCountryByName("Iran") ?? CountryModel(name: "Iran", code: "IR", flag: "🇮🇷"), imageName: "tehran_image"),
            CityModel(name: "Shanghai", country: service.getCountryByName("China") ?? CountryModel(name: "China", code: "CN", flag: "🇨🇳"), imageName: "shanghai_image"),
            CityModel(name: "Sydney", country: service.getCountryByName("Australia") ?? CountryModel(name: "Australia", code: "AU", flag: "🇦🇺"), imageName: "sydney_opera_house_image"),
            CityModel(name: "Melbourne", country: service.getCountryByName("Australia") ?? CountryModel(name: "Australia", code: "AU", flag: "🇦🇺"), imageName: "melbourne_image"),
            CityModel(name: "Buenos Aires", country: service.getCountryByName("Argentina") ?? CountryModel(name: "Argentina", code: "AR", flag: "🇦🇷"), imageName: "buenos_aires_image"),
            CityModel(name: "Santiago", country: service.getCountryByName("Chile") ?? CountryModel(name: "Chile", code: "CL", flag: "🇨🇱"), imageName: "santiago_image"),
            CityModel(name: "Lima", country: service.getCountryByName("Peru") ?? CountryModel(name: "Peru", code: "PE", flag: "🇵🇪"), imageName: "lima_image"),
            CityModel(name: "Bogota", country: service.getCountryByName("Colombia") ?? CountryModel(name: "Colombia", code: "CO", flag: "🇨🇴"), imageName: "bogota_image"),
            CityModel(name: "Caracas", country: service.getCountryByName("Venezuela") ?? CountryModel(name: "Venezuela", code: "VE", flag: "🇻🇪"), imageName: "caracas_image"),
            CityModel(name: "Port of Spain", country: service.getCountryByName("Trinidad and Tobago") ?? CountryModel(name: "Trinidad and Tobago", code: "TT", flag: "🇹🇹"), imageName: "port_of_spain_image"),
            CityModel(name: "Kingston", country: service.getCountryByName("Jamaica") ?? CountryModel(name: "Jamaica", code: "JM", flag: "🇯🇲"), imageName: "kingston_image"),
            CityModel(name: "Mexico City", country: service.getCountryByName("Mexico") ?? CountryModel(name: "Mexico", code: "MX", flag: "🇲🇽"), imageName: "mexico_city_image"),
            CityModel(name: "Los Angeles", country: service.getCountryByName("United States") ?? CountryModel(name: "United States", code: "US", flag: "🇺🇸"), imageName: "los_angeles_image"),
            CityModel(name: "San Francisco", country: service.getCountryByName("United States") ?? CountryModel(name: "United States", code: "US", flag: "🇺🇸"), imageName: "san_francisco_image"),
            CityModel(name: "Vancouver", country: service.getCountryByName("Canada") ?? CountryModel(name: "Canada", code: "CA", flag: "🇨🇦"), imageName: "vancouver_image"),
            CityModel(name: "Houston", country: service.getCountryByName("United States") ?? CountryModel(name: "United States", code: "US", flag: "🇺🇸"), imageName: "houston_image"),
            CityModel(name: "Dallas", country: service.getCountryByName("United States") ?? CountryModel(name: "United States", code: "US", flag: "🇺🇸"), imageName: "dallas_image"),
            CityModel(name: "Chicago", country: service.getCountryByName("United States") ?? CountryModel(name: "United States", code: "US", flag: "🇺🇸"), imageName: "chicago_image"),
            CityModel(name: "Washington", country: service.getCountryByName("United States") ?? CountryModel(name: "United States", code: "US", flag: "🇺🇸"), imageName: "washington_image"),
            CityModel(name: "New York", country: service.getCountryByName("United States") ?? CountryModel(name: "United States", code: "US", flag: "🇺🇸"), imageName: "new_york_image"),
            CityModel(name: "Toronto", country: service.getCountryByName("Canada") ?? CountryModel(name: "Canada", code: "CA", flag: "🇨🇦"), imageName: "toronto_image"),
            CityModel(name: "Montreal", country: service.getCountryByName("Canada") ?? CountryModel(name: "Canada", code: "CA", flag: "🇨🇦"), imageName: "montreal_image"),
            CityModel(name: "Madrid", country: service.getCountryByName("Spain") ?? CountryModel(name: "Spain", code: "ES", flag: "🇪🇸"), imageName: "madrid_image"),
            CityModel(name: "Hong Kong", country: service.getCountryByName("China") ?? CountryModel(name: "China", code: "CN", flag: "🇭🇰"), imageName: "hong_kong_image"),
            CityModel(name: "Seoul", country: service.getCountryByName("South Korea") ?? CountryModel(name: "South Korea", code: "KR", flag: "🇰🇷"), imageName: "seoul_image"),
            CityModel(name: "Mumbai", country: service.getCountryByName("India") ?? CountryModel(name: "India", code: "IN", flag: "🇮🇳"), imageName: "mumbai_image")
        ]
    }
}

extension CityModel {
    var coordinate: CLLocationCoordinate2D {
        switch self.name {
        case "London": return CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        case "Paris": return CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        case "Tokyo": return CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)
        case "Berlin": return CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        case "Barcelona": return CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734)
        case "Rome": return CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
        case "Beijing": return CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
        case "Cairo": return CLLocationCoordinate2D(latitude: 30.0444, longitude: 31.2357)
        case "New Delhi": return CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090)
        case "Rio De Janeiro": return CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729)
        case "Moscow": return CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176)
        case "Amsterdam": return CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)
        case "Athens": return CLLocationCoordinate2D(latitude: 37.9838, longitude: 23.7275)
        case "Bangkok": return CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018)
        case "Lagos": return CLLocationCoordinate2D(latitude: 6.5244, longitude: 3.3792)
        case "Cape Town": return CLLocationCoordinate2D(latitude: -33.9249, longitude: 18.4241)
        case "Nairobi": return CLLocationCoordinate2D(latitude: -1.286389, longitude: 36.817223)
        case "Stockholm": return CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686)
        case "Istanbul": return CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        case "Copenhagen": return CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683)
        case "Dubai": return CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708)
        case "Tehran": return CLLocationCoordinate2D(latitude: 35.6892, longitude: 51.3890)
        case "Shanghai": return CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)
        case "Sydney": return CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
        case "Melbourne": return CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)
        case "Buenos Aires": return CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816)
        case "Santiago": return CLLocationCoordinate2D(latitude: -33.4489, longitude: -70.6693)
        case "Lima": return CLLocationCoordinate2D(latitude: -12.0464, longitude: -77.0428)
        case "Bogota": return CLLocationCoordinate2D(latitude: 4.7110, longitude: -74.0721)
        case "Caracas": return CLLocationCoordinate2D(latitude: 10.4806, longitude: -66.9036)
        case "Port of Spain": return CLLocationCoordinate2D(latitude: 10.6918, longitude: -61.2225)
        case "Kingston": return CLLocationCoordinate2D(latitude: 17.9714, longitude: -76.7936)
        case "Mexico City": return CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)
        case "Los Angeles": return CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
        case "San Francisco": return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        case "Vancouver": return CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207)
        case "Houston": return CLLocationCoordinate2D(latitude: 29.7604, longitude: -95.3698)
        case "Dallas": return CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970)
        case "Chicago": return CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298)
        case "Washington": return CLLocationCoordinate2D(latitude: 38.9072, longitude: -77.0369)
        case "New York": return CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        case "Toronto": return CLLocationCoordinate2D(latitude: 43.6511, longitude: -79.3832)
        case "Montreal": return CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673)
        case "Madrid": return CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038)
        case "Hong Kong": return CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694)
        case "Seoul": return CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        case "Mumbai": return CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)
        
        default: return CLLocationCoordinate2D()
        }
    }
}
