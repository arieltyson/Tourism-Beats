import EventKit
import EventKitUI
import SwiftUI

/// The system's New Event sheet, filled in with a flight.
///
/// Its calendar picker lists every account on the device, so one sheet adds
/// the flight to iCloud, Google, Outlook, and Exchange calendars, and to
/// Notion Calendar through Google. The sheet runs outside the app, so
/// Tourism Beats needs no calendar access and never reads your calendars.
/// EventKitUI offers this only as a view controller.
struct FlightEventEditor: UIViewControllerRepresentable {
    let event: FlightCalendarEvent
    let onComplete: (_ saved: Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let draft = EKEvent(eventStore: store)
        draft.title = event.title
        draft.startDate = event.start
        draft.endDate = event.end
        draft.timeZone = event.timeZone
        draft.location = event.location
        draft.notes = event.notes
        draft.url = event.url
        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.event = draft
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: EKEventEditViewController, context: Context) {}

    /// EventKitUI calls its delegate on the main thread, which the isolated
    /// conformance states without pretending the protocol says so.
    @MainActor
    final class Coordinator: NSObject, @MainActor EKEventEditViewDelegate {
        private let onComplete: (Bool) -> Void

        init(onComplete: @escaping (Bool) -> Void) {
            self.onComplete = onComplete
        }

        func eventEditViewController(
            _ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction
        ) {
            onComplete(action == .saved)
        }
    }
}
