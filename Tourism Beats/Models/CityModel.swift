import CoreLocation

struct CityModel: Identifiable, Equatable {
    let id: String
    let name: String
    let country: CountryModel
    let imageName: String
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: CityModel, rhs: CityModel) -> Bool {
        lhs.id == rhs.id
    }
}
