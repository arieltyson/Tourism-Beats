import AppIntents

/// Moves the widget on to the next upcoming flight. WidgetKit redraws the
/// widget once it's done.
struct ShowNextFlightIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Next Flight"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        let flights = try await FlightCountdownStore().load()
        FlightWidgetSelection.select(
            FlightWidgetCarousel.id(after: FlightWidgetSelection.selectedID(), in: flights, at: .now)
        )
        return .result()
    }
}
