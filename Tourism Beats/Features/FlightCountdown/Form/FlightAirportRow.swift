import SwiftUI

/// One end of the route: a clear label, and the airport once it's chosen.
struct FlightAirportRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    let airport: Airport?

    var body: some View {
        LabeledContent {
            if let airport {
                if airport.servedCity.isEmpty {
                    Text(airport.code)
                } else {
                    Text("\(airport.servedCity) \(Text(airport.code).foregroundStyle(.secondary))")
                }
            } else {
                FlightFormPlaceholder()
            }
        } label: {
            Label(title, systemImage: systemImage)
        }
    }
}
