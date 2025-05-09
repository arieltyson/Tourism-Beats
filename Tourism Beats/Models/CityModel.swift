import Foundation

struct CityModel: Identifiable {
    let id = UUID()
    let name: String
    let country: CountryModel
    let imageName: String
}
