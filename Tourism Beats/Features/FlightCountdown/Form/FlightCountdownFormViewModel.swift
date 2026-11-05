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
    /// The card's photos in the order chosen: saved ones and ones just chosen.
    private(set) var photos: [FlightCardPhoto]
    /// Every photo's pixels, saved or just chosen, by photo.
    private(set) var images: [UUID: CGImage]
    /// Photos chosen since the form opened, prepared and waiting to be saved.
    private(set) var newPhotos: [UUID: FlightPhoto] = [:]
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
        images: [UUID: CGImage] = [:],
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
        photos = flight?.photos ?? []
        self.images = images
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

    /// The photos ready to draw, whether or not the card uses them yet.
    var cardImages: [FlightCardImage] {
        photos.compactMap { photo in
            images[photo.id].map { FlightCardImage(id: photo.id, image: $0, framing: photo.framing) }
        }
    }

    var hasChanges: Bool {
        guard let initialFlight else {
            return airline != nil || !flightNumber.isEmpty || origin != nil || destination != nil || !photos.isEmpty
        }
        return flight != initialFlight
    }

    var canSave: Bool {
        airline != nil && !flightNumber.isEmpty
            && origin != nil && destination != nil && origin?.code != destination?.code
            && TimeZone(identifier: timeZoneIdentifier) != nil
            && (cardTheme != .photo || !photos.isEmpty) && !isPreparingPhoto
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
            photos: cardTheme == .photo ? photos : [],
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

    /// Makes the photos chosen in the picker the card's background, in the
    /// order they were chosen. Photos the card already has keep their
    /// framing; new ones are prepared. Choosing none returns the card to
    /// its first design.
    func usePhotos(_ sources: [FlightPhotoSource]) async {
        isPreparingPhoto = true
        defer { isPreparingPhoto = false }
        var chosen: [FlightCardPhoto] = []
        for source in sources.prefix(FlightCountdownStyle.maximumPhotoCount) {
            if let identifier = source.identifier,
               let existing = photos.first(where: { $0.sourceIdentifier == identifier }) {
                chosen.append(existing)
                continue
            }
            do {
                let prepared = try await FlightPhotoProcessor.prepare(try await source.load())
                let photo = FlightCardPhoto(sourceIdentifier: source.identifier)
                images[photo.id] = prepared.image
                newPhotos[photo.id] = prepared
                chosen.append(photo)
            } catch {
                photoErrorMessage = error.localizedDescription
            }
        }
        // Photos that all failed to open leave the card as it was.
        guard sources.isEmpty || !chosen.isEmpty else { return }
        let kept = Set(chosen.map(\.id))
        for photo in photos where !kept.contains(photo.id) {
            newPhotos[photo.id] = nil
        }
        photos = chosen
        if !chosen.isEmpty {
            cardTheme = .photo
        } else if cardTheme == .photo, let first = FlightCardTheme.gradients.first {
            cardTheme = first
        }
    }

    /// Keeps the framing chosen for each photo.
    func applyFramings(_ framings: [UUID: FlightPhotoFraming]) {
        for index in photos.indices {
            if let framing = framings[photos[index].id] { photos[index].framing = framing }
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
