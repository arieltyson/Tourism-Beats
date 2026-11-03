import SwiftUI

/// The picker for each part of the flight form.
struct FlightCountdownFormDestination: View {
    let route: FlightCountdownFormRoute
    let form: FlightCountdownFormViewModel

    var body: some View {
        switch route {
        case .airline:
            AirlinePicker(selection: form.airline) { form.select(airline: $0) }
        case .origin:
            AirportPicker(title: "Departure Airport", selection: form.origin) { form.select(origin: $0) }
        case .destination:
            AirportPicker(title: "Arrival Airport", selection: form.destination) { form.select(destination: $0) }
        case .timeZone:
            FlightTimeZonePicker(selection: form.timeZoneIdentifier, referenceDate: form.departure) {
                form.setTimeZone($0)
            }
        }
    }
}
