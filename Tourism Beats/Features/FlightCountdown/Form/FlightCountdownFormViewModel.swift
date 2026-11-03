import CoreGraphics
import Foundation
import Observation

/// The flight being added or edited, validated as it's entered.
@MainActor
@Observable
final class FlightCountdownFormViewModel {
    private(set) var airline: Airline?
    private(set) var origin: Airport?
    private(set) var destination: Airport?
    /// The departure as an absolute moment, shown in ``timeZone``.
    var departure: Date
    private(set) var timeZoneIdentifier: String
    var cardTheme: FlightCardTheme
    /// The card photo: the saved one, or one just chosen.
    private(set) var photo: CGImage?
    private(set) var photoChange: FlightPhotoChange = .unchanged
    private(set) var isPreparingPhoto = false
    var photoErrorMessage: String?
    let isEditing: Bool

    /// Digits only, as long as an airline's longest flight number.
    var flightNumber: String {
        get { storedFlightNumber }
        set {
            storedFlightNumber = Self.digits(in: newValue)
        }
    }

    private var storedFlightNumber: String
    private let id: UUID
    private let countdownStartedAt: Date?
    private var initialFlight: CountdownFlight?

    init(
        flight: CountdownFlight? = nil,
        photo: CGImage? = nil,
        airlines: AirlineDirectory = .bundled,
        airports: AirportDirectory = .bundled,
        now: Date = .now
    ) {
        id = flight?.id ?? UUID()
        isEditing = flight != nil
        countdownStartedAt = flight == nil ? now : flight?.countdownStartedAt
        timeZoneIdentifier = flight?.timeZoneIdentifier ?? TimeZone.current.identifier
        departure = flight?.departure ?? Self.suggestedDeparture(after: now)
        storedFlightNumber = Self.digits(in: flight?.flightNumber ?? "")
        cardTheme = flight?.cardTheme ?? .twilight
        self.photo = photo
        if let flight {
            airline = flight.airlineCode.isEmpty ? nil
                : airlines.airline(code: flight.airlineCode) ?? .unlisted(code: flight.airlineCode)
            origin = airports.airport(code: flight.origin) ?? .unlisted(code: flight.origin)
            destination = airports.airport(code: flight.destination) ?? .unlisted(code: flight.destination)
        }
        // Compare against the flight as this form describes it, so filling in
        // names for an older flight doesn't count as an edit.
        initialFlight = isEditing ? self.flight : nil
    }

    var timeZone: TimeZone { TimeZone(identifier: timeZoneIdentifier) ?? .gmt }
    var timeZoneLabel: String { FlightTimeZoneOption(timeZone: timeZone, at: departure).summary }

    var hasChanges: Bool {
        if case .replace = photoChange { return true }
        guard let initialFlight else {
            return airline != nil || !flightNumber.isEmpty || origin != nil || destination != nil
        }
        return flight != initialFlight
    }

    var canSave: Bool {
        airline != nil && !flightNumber.isEmpty
            && origin != nil && destination != nil && origin?.code != destination?.code
            && TimeZone(identifier: timeZoneIdentifier) != nil
            && (cardTheme != .photo || photo != nil) && !isPreparingPhoto
    }

    /// Explains whose clock the departure time is on.
    var departureFooter: String {
        guard let origin, origin.isListed else {
            return String(localized: "Use the local time at the departure airport.")
        }
        return String(localized: "Use the local time in \(origin.servedCity).")
    }

    var flight: CountdownFlight {
        CountdownFlight(
            id: id,
            airlineCode: airline?.code ?? "",
            airlineName: airline.flatMap { $0.name == $0.code ? nil : $0.name },
            flightNumber: flightNumber,
            origin: origin?.code ?? "",
            originCity: origin.flatMap(Self.city),
            destination: destination?.code ?? "",
            destinationCity: destination.flatMap(Self.city),
            departure: departure,
            timeZoneIdentifier: timeZoneIdentifier,
            cardTheme: cardTheme,
            countdownStartedAt: countdownStartedAt
        )
    }

    func select(airline: Airline) {
        self.airline = airline
    }

    /// Choosing where the flight leaves from also sets the time zone.
    func select(origin: Airport) {
        self.origin = origin
        if let zone = origin.timeZone { setTimeZone(zone) }
    }

    func select(destination: Airport) {
        self.destination = destination
    }

    /// Prepares a library photo and makes it the card's background.
    func usePhoto(_ data: Data) async {
        isPreparingPhoto = true
        defer { isPreparingPhoto = false }
        do {
            let prepared = try await FlightPhotoProcessor.prepare(data)
            photo = prepared.image
            photoChange = .replace(prepared)
            cardTheme = .photo
        } catch {
            photoErrorMessage = error.localizedDescription
        }
    }

    /// Moves the departure into another time zone, keeping the time on the
    /// clock: 1:50 PM stays 1:50 PM, now in the new zone.
    func setTimeZone(_ identifier: String) {
        guard identifier != timeZoneIdentifier, let newZone = TimeZone(identifier: identifier) else { return }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let wallClock = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: departure)
        calendar.timeZone = newZone
        if let moved = calendar.date(from: wallClock) { departure = moved }
        timeZoneIdentifier = identifier
    }

    private static func digits(in value: String) -> String {
        String(value.filter { $0.isASCII && $0.isNumber }.prefix(FlightCountdownTokens.maximumFlightNumberLength))
    }

    private static func city(of airport: Airport) -> String? {
        airport.servedCity.isEmpty ? nil : airport.servedCity
    }

    /// Tomorrow, on the hour: a plausible departure to adjust from.
    private static func suggestedDeparture(after now: Date) -> Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        return Calendar.current.nextDate(
            after: tomorrow, matching: DateComponents(minute: 0), matchingPolicy: .nextTime
        ) ?? tomorrow
    }
}
