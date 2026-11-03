import CoreTransferable
import UniformTypeIdentifiers

/// Shares as an `.ics` file, so the share sheet can send a flight to any
/// calendar app, or to the person meeting it.
extension FlightCalendarEvent: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .calendarEvent) { event in
            FlightICalendarWriter.data(for: event)
        }
        .suggestedFileName { $0.fileName }
    }
}
