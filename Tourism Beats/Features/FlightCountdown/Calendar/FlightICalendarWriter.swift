import Foundation

/// Writes a flight event as an iCalendar file (RFC 5545), which every
/// calendar app can import: Apple Calendar, Google Calendar, Outlook, and
/// Notion Calendar among them.
enum FlightICalendarWriter {
    /// iCalendar lines end in CRLF and fold past 75 octets.
    private static let lineBreak = "\r\n"
    private static let maximumLineOctets = 75

    static func document(for event: FlightCalendarEvent, stampedAt stamp: Date = .now) -> String {
        var lines = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//Tourism Beats//Flight Countdown//EN",
            "CALSCALE:GREGORIAN",
            "METHOD:PUBLISH",
            "BEGIN:VEVENT",
            "UID:\(escaped(event.id))",
            "DTSTAMP:\(utc(stamp))",
            // UTC times are exact everywhere; calendars show them in local time.
            "DTSTART:\(utc(event.start))",
            "DTEND:\(utc(event.end))",
            "SUMMARY:\(escaped(event.title))",
            "LOCATION:\(escaped(event.location))",
            "DESCRIPTION:\(escaped(event.notes))"
        ]
        if let url = event.url { lines.append("URL:\(url.absoluteString)") }
        lines += ["END:VEVENT", "END:VCALENDAR"]
        return lines.map(folded).joined(separator: lineBreak) + lineBreak
    }

    static func data(for event: FlightCalendarEvent) -> Data {
        Data(document(for: event).utf8)
    }

    /// Such as `20261220T215000Z`.
    static func utc(_ date: Date) -> String {
        date.formatted(Date.ISO8601FormatStyle(dateSeparator: .omitted, timeSeparator: .omitted, timeZone: .gmt))
    }

    /// Escapes the characters iCalendar text treats as syntax.
    static func escaped(_ text: String) -> String {
        text.replacing("\\", with: "\\\\")
            .replacing(";", with: "\\;")
            .replacing(",", with: "\\,")
            .replacing("\r\n", with: "\\n")
            .replacing("\n", with: "\\n")
    }

    /// Splits a long line into 75-octet pieces, each continuation starting
    /// with a space, without breaking a character apart.
    static func folded(_ line: String) -> String {
        var pieces: [String] = []
        var current = ""
        var octets = 0
        for character in line {
            let size = String(character).utf8.count
            // Continuation lines spend one octet on their leading space.
            let limit = pieces.isEmpty ? maximumLineOctets : maximumLineOctets - 1
            if octets + size > limit {
                pieces.append(current)
                current = ""
                octets = 0
            }
            current.append(character)
            octets += size
        }
        pieces.append(current)
        return pieces.joined(separator: "\(lineBreak) ")
    }
}
