import CoreLocation
import Foundation

struct CityModel: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let country: CountryModel
    let imageName: String
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: CityModel, rhs: CityModel) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}
