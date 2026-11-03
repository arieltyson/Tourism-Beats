import Foundation

/// Estimates how long a flight takes from the distance between its airports,
/// so a calendar event ends near when it lands. People can adjust it before
/// saving; it is a starting point, not a schedule.
enum FlightDurationEstimator {
    private static let earthRadiusKilometres = 6_371.0
    /// A typical airliner's average speed over a whole trip.
    private static let cruiseKilometresPerHour = 800.0
    /// Taxi, climb, and approach, which distance alone doesn't account for.
    private static let groundAndClimb: TimeInterval = 30 * FlightCountdownConfiguration.secondsPerMinute
    /// Estimates round to this, as airline schedules do.
    private static let rounding: TimeInterval = 5 * FlightCountdownConfiguration.secondsPerMinute
    /// Used when either airport's location is unknown.
    static let fallback: TimeInterval = FlightCountdownConfiguration.secondsPerHour

    static func duration(from origin: Airport?, to destination: Airport?) -> TimeInterval {
        guard let lat1 = origin?.latitude, let lon1 = origin?.longitude,
              let lat2 = destination?.latitude, let lon2 = destination?.longitude else { return fallback }
        let distance = greatCircleKilometres(lat1, lon1, lat2, lon2)
        let flying = distance / cruiseKilometresPerHour * FlightCountdownConfiguration.secondsPerHour
        return ((flying + groundAndClimb) / rounding).rounded() * rounding
    }

    /// The haversine distance between two coordinates in degrees.
    static func greatCircleKilometres(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let toRadians = Double.pi / 180
        let deltaLatitude = (lat2 - lat1) * toRadians
        let deltaLongitude = (lon2 - lon1) * toRadians
        let haversine = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(lat1 * toRadians) * cos(lat2 * toRadians) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        return 2 * earthRadiusKilometres * asin(min(1, haversine.squareRoot()))
    }
}
