import WidgetKit

struct FlightCountdownProvider: TimelineProvider, Sendable {
    func placeholder(in context: Context) -> FlightCountdownEntry {
        sample
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (FlightCountdownEntry) -> Void) {
        if context.isPreview { completion(sample); return }
        Task {
            do {
                let flights = try await FlightCountdownStore().load()
                let now = Date.now
                completion(FlightCountdownEntry(date: now, flight: CountdownFlight.next(in: flights, after: now)))
            } catch {
                completion(FlightCountdownEntry(date: .now, flight: nil, isUnavailable: true))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<FlightCountdownEntry>) -> Void) {
        Task {
            let now = Date.now
            do {
                let flights = try await FlightCountdownStore().load()
                let entries = FlightCountdownSchedule.dates(for: flights, from: now).map { date in
                    FlightCountdownEntry(date: date, flight: CountdownFlight.next(in: flights, after: date))
                }
                completion(Timeline(entries: entries, policy: .atEnd))
            } catch {
                let entry = FlightCountdownEntry(date: now, flight: nil, isUnavailable: true)
                completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(FlightCountdownConfiguration.secondsPerHour))))
            }
        }
    }

    private var sample: FlightCountdownEntry {
        FlightCountdownEntry(date: .now, flight: CountdownFlight(
            airlineCode: "AC", airlineName: "Air Canada", flightNumber: "123",
            origin: "YVR", originCity: "Vancouver", destination: "YYZ", destinationCity: "Toronto",
            departure: Date.now.addingTimeInterval(3 * FlightCountdownConfiguration.secondsPerDay),
            timeZoneIdentifier: "America/Vancouver"
        ))
    }
}
