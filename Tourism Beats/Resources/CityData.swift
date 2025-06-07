import Foundation
import MapKit

struct CityData {
    static func cities(countryService: CountryServiceProtocol)
        -> [CityModel]
    {
        let service = countryService

        return [
            CityModel(
                name: "London",
                country: service.getCountryByName("United Kingdom")!,
                imageName: "big_ben_image",
                coordinate: .init(latitude: 51.5074, longitude: -0.1278)
            ),
            CityModel(
                name: "Paris",
                country: service.getCountryByName("France")!,
                imageName: "eiffel_tower_image",
                coordinate: .init(latitude: 48.8566, longitude: 2.3522)
            ),
            CityModel(
                name: "Tokyo",
                country: service.getCountryByName("Japan")!,
                imageName: "tokyo_tower_image",
                coordinate: .init(latitude: 35.6895, longitude: 139.6917)
            ),
            CityModel(
                name: "Berlin",
                country: service.getCountryByName("Germany")!,
                imageName: "brandenburg_gate_image",
                coordinate: .init(latitude: 52.5200, longitude: 13.4050)
            ),
            CityModel(
                name: "Barcelona",
                country: service.getCountryByName("Spain")!,
                imageName: "sagrada_familia_image",
                coordinate: .init(latitude: 41.3851, longitude: 2.1734)
            ),
            CityModel(
                name: "Rome",
                country: service.getCountryByName("Italy")!,
                imageName: "colosseum_image",
                coordinate: .init(latitude: 41.9028, longitude: 12.4964)
            ),
            CityModel(
                name: "Beijing",
                country: service.getCountryByName("China")!,
                imageName: "great_wall_of_china_image",
                coordinate: .init(latitude: 39.9042, longitude: 116.4074)
            ),
            CityModel(
                name: "Cairo",
                country: service.getCountryByName("Egypt")!,
                imageName: "great_pyramid_of_giza_image",
                coordinate: .init(latitude: 30.0444, longitude: 31.2357)
            ),
            CityModel(
                name: "New Delhi",
                country: service.getCountryByName("India")!,
                imageName: "india_gate_image",
                coordinate: .init(latitude: 28.6139, longitude: 77.2090)
            ),
            CityModel(
                name: "Rio De Janeiro",
                country: service.getCountryByName("Brazil")!,
                imageName: "christ_the_redeemer_image",
                coordinate: .init(latitude: -22.9068, longitude: -43.1729)
            ),
            CityModel(
                name: "Moscow",
                country: service.getCountryByName("Russia")!,
                imageName: "kremlin_image",
                coordinate: .init(latitude: 55.7558, longitude: 37.6176)
            ),
            CityModel(
                name: "Amsterdam",
                country: service.getCountryByName("Netherlands")!,
                imageName: "van_gogh_museum_image",
                coordinate: .init(latitude: 52.3676, longitude: 4.9041)
            ),
            CityModel(
                name: "Athens",
                country: service.getCountryByName("Greece")!,
                imageName: "the_acropolis_image",
                coordinate: .init(latitude: 37.9838, longitude: 23.7275)
            ),
            CityModel(
                name: "Bangkok",
                country: service.getCountryByName("Thailand")!,
                imageName: "grand_palace_image",
                coordinate: .init(latitude: 13.7563, longitude: 100.5018)
            ),
            CityModel(
                name: "Lagos",
                country: service.getCountryByName("Nigeria")!,
                imageName: "lagos_image",
                coordinate: .init(latitude: 6.5244, longitude: 3.3792)
            ),
            CityModel(
                name: "Cape Town",
                country: service.getCountryByName("South Africa")!,
                imageName: "cape_town_image",
                coordinate: .init(latitude: -33.9249, longitude: 18.4241)
            ),
            CityModel(
                name: "Nairobi",
                country: service.getCountryByName("Kenya")!,
                imageName: "nairobi_image",
                coordinate: .init(latitude: -1.286389, longitude: 36.817223)
            ),
            CityModel(
                name: "Stockholm",
                country: service.getCountryByName("Sweden")!,
                imageName: "stockholm_image",
                coordinate: .init(latitude: 59.3293, longitude: 18.0686)
            ),
            CityModel(
                name: "Istanbul",
                country: service.getCountryByName("Turkey")!,
                imageName: "istanbul_image",
                coordinate: .init(latitude: 41.0082, longitude: 28.9784)
            ),
            CityModel(
                name: "Copenhagen",
                country: service.getCountryByName("Denmark")!,
                imageName: "copenhagen_image",
                coordinate: .init(latitude: 55.6761, longitude: 12.5683)
            ),
            CityModel(
                name: "Dubai",
                country: service.getCountryByName("United Arab Emirates")!,
                imageName: "dubai_image",
                coordinate: .init(latitude: 25.2048, longitude: 55.2708)
            ),
            CityModel(
                name: "Tehran",
                country: service.getCountryByName("Iran")!,
                imageName: "tehran_image",
                coordinate: .init(latitude: 35.6892, longitude: 51.3890)
            ),
            CityModel(
                name: "Shanghai",
                country: service.getCountryByName("China")!,
                imageName: "shanghai_image",
                coordinate: .init(latitude: 31.2304, longitude: 121.4737)
            ),
            CityModel(
                name: "Sydney",
                country: service.getCountryByName("Australia")!,
                imageName: "sydney_opera_house_image",
                coordinate: .init(latitude: -33.8688, longitude: 151.2093)
            ),
            CityModel(
                name: "Melbourne",
                country: service.getCountryByName("Australia")!,
                imageName: "melbourne_image",
                coordinate: .init(latitude: -37.8136, longitude: 144.9631)
            ),
            CityModel(
                name: "Buenos Aires",
                country: service.getCountryByName("Argentina")!,
                imageName: "buenos_aires_image",
                coordinate: .init(latitude: -34.6037, longitude: -58.3816)
            ),
            CityModel(
                name: "Santiago",
                country: service.getCountryByName("Chile")!,
                imageName: "santiago_image",
                coordinate: .init(latitude: -33.4489, longitude: -70.6693)
            ),
            CityModel(
                name: "Lima",
                country: service.getCountryByName("Peru")!,
                imageName: "lima_image",
                coordinate: .init(latitude: -12.0464, longitude: -77.0428)
            ),
            CityModel(
                name: "Bogota",
                country: service.getCountryByName("Colombia")!,
                imageName: "bogota_image",
                coordinate: .init(latitude: 4.7110, longitude: -74.0721)
            ),
            CityModel(
                name: "Caracas",
                country: service.getCountryByName("Venezuela")!,
                imageName: "caracas_image",
                coordinate: .init(latitude: 10.4806, longitude: -66.9036)
            ),
            CityModel(
                name: "Port of Spain",
                country: service.getCountryByName("Trinidad and Tobago")!,
                imageName: "port_of_spain_image",
                coordinate: .init(latitude: 10.6520, longitude: -61.5157)
            ),
            CityModel(
                name: "Kingston",
                country: service.getCountryByName("Jamaica")!,
                imageName: "kingston_image",
                coordinate: .init(latitude: 17.9714, longitude: -76.7936)
            ),
            CityModel(
                name: "Mexico City",
                country: service.getCountryByName("Mexico")!,
                imageName: "mexico_city_image",
                coordinate: .init(latitude: 19.4326, longitude: -99.1332)
            ),
            CityModel(
                name: "Los Angeles",
                country: service.getCountryByName("United States of America")!,
                imageName: "los_angeles_image",
                coordinate: .init(latitude: 34.0522, longitude: -118.2437)
            ),
            CityModel(
                name: "San Francisco",
                country: service.getCountryByName("United States of America")!,
                imageName: "san_francisco_image",
                coordinate: .init(latitude: 37.7749, longitude: -122.4194)
            ),
            CityModel(
                name: "Vancouver",
                country: service.getCountryByName("Canada")!,
                imageName: "vancouver_image",
                coordinate: .init(latitude: 49.2827, longitude: -123.1207)
            ),
            CityModel(
                name: "Houston",
                country: service.getCountryByName("United States of America")!,
                imageName: "houston_image",
                coordinate: .init(latitude: 29.7604, longitude: -95.3698)
            ),
            CityModel(
                name: "Dallas",
                country: service.getCountryByName("United States of America")!,
                imageName: "dallas_image",
                coordinate: .init(latitude: 32.7767, longitude: -96.7970)
            ),
            CityModel(
                name: "Chicago",
                country: service.getCountryByName("United States of America")!,
                imageName: "chicago_image",
                coordinate: .init(latitude: 41.8781, longitude: -87.6298)
            ),
            CityModel(
                name: "Washington",
                country: service.getCountryByName("United States of America")!,
                imageName: "washington_image",
                coordinate: .init(latitude: 38.9072, longitude: -77.0369)
            ),
            CityModel(
                name: "New York",
                country: service.getCountryByName("United States of America")!,
                imageName: "new_york_image",
                coordinate: .init(latitude: 40.7128, longitude: -74.0060)
            ),
            CityModel(
                name: "Toronto",
                country: service.getCountryByName("Canada")!,
                imageName: "toronto_image",
                coordinate: .init(latitude: 43.6511, longitude: -79.3832)
            ),
            CityModel(
                name: "Montreal",
                country: service.getCountryByName("Canada")!,
                imageName: "montreal_image",
                coordinate: .init(latitude: 45.5017, longitude: -73.5673)
            ),
            CityModel(
                name: "Madrid",
                country: service.getCountryByName("Spain")!,
                imageName: "madrid_image",
                coordinate: .init(latitude: 40.4168, longitude: -3.7038)
            ),
            CityModel(
                name: "Hong Kong",
                country: service.getCountryByName("China")!,
                imageName: "hong_kong_image",
                coordinate: .init(latitude: 22.3193, longitude: 114.1694)
            ),
            CityModel(
                name: "Seoul",
                country: service.getCountryByName("South Korea")!,
                imageName: "seoul_image",
                coordinate: .init(latitude: 37.5665, longitude: 126.9780)
            ),
            CityModel(
                name: "Mumbai",
                country: service.getCountryByName("India")!,
                imageName: "mumbai_image",
                coordinate: .init(latitude: 19.0760, longitude: 72.8777)
            ),
        ]
    }
}
