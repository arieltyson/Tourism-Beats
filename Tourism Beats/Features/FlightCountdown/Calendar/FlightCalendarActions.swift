import SwiftUI

/// Calendar actions for a flight's context menu: add it to a calendar on
/// this device, or share it as an event file with any app or person.
struct FlightCalendarActions: View {
    let event: FlightCalendarEvent
    let onAdd: () -> Void

    var body: some View {
        Button("Add to Calendar", systemImage: "calendar.badge.plus", action: onAdd)
        ShareLink(
            "Share Event", item: event,
            preview: SharePreview(event.title, image: Image(systemName: "calendar"))
        )
    }
}
