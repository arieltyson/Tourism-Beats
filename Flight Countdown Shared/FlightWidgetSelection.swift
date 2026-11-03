import Foundation

/// Remembers which flight the widget was moved to, in the app group the
/// widget and its buttons share.
enum FlightWidgetSelection {
    private static let key = "FlightWidgetSelectedFlightID"

    static func selectedID(in defaults: UserDefaults? = UserDefaults(suiteName: FlightCountdownConfiguration.appGroup)) -> UUID? {
        defaults?.string(forKey: key).flatMap(UUID.init(uuidString:))
    }

    static func select(_ id: UUID?, in defaults: UserDefaults? = UserDefaults(suiteName: FlightCountdownConfiguration.appGroup)) {
        defaults?.set(id?.uuidString, forKey: key)
    }
}
