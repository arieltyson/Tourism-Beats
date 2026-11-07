import Foundation
import SwiftData

// MARK: - BucketListItem

/// Somewhere to go or something to do, someday.
///
/// A place is a country, and optionally one of the app's cities in it; an
/// activity is whatever the person wrote. Every property has a default so
/// the model stays ready for CloudKit sync.
@Model
final class BucketListItem {
    var kindRaw: String = BucketListItemKind.activity.rawValue

    /// The activity, or the place's name as shown: "Kyoto" or "Japan".
    var title: String = ""

    /// The place's country, by ISO code and name. Empty for activities.
    var countryCode: String = ""
    var countryName: String = ""

    /// The catalog city, for a place that names one. It links the item to
    /// that city's page, so the page knows the city is on the list.
    var cityID: String?
    var cityName: String?
    var cityRegion: String?

    var isCompleted: Bool = false
    var dateAdded: Date = Date.now

    init(activity: String) {
        self.kindRaw = BucketListItemKind.activity.rawValue
        self.title = activity
        self.dateAdded = Date.now
    }

    init(country: CountryModel, city: CityModel? = nil) {
        self.kindRaw = BucketListItemKind.place.rawValue
        self.title = city?.name ?? country.name
        self.countryCode = country.code
        self.countryName = country.name
        self.cityID = city?.id
        self.cityName = city?.name
        self.cityRegion = city?.regionName
        self.dateAdded = Date.now
    }

    var kind: BucketListItemKind {
        BucketListItemKind(rawValue: self.kindRaw) ?? .activity
    }

    /// Where a place is, beneath its name: "Kyoto, Japan" reads as "Japan",
    /// "Portland, Maine" as "Maine, United States". Nil for a country alone
    /// and for activities.
    var placeDetail: String? {
        guard self.kind == .place, self.cityName != nil else { return nil }
        guard let cityRegion, cityRegion != self.countryName else { return self.countryName }
        return "\(cityRegion), \(self.countryName)"
    }
}
