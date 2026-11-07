import SwiftUI

@MainActor
@Observable
final class TimeViewModel {
    let timeZone: TimeZone

    init(timeZone: TimeZone) {
        self.timeZone = timeZone
    }

    /// The city's local time and its offset from GMT, such as "2:45 PM (GMT+1)",
    /// "14:45 (GMT+1)", or "8:15 PM (GMT+5:30)".
    ///
    /// The time follows the reader's locale, including whether they use a
    /// 12- or 24-hour clock. The offset is the one in effect at `date`, with
    /// minutes for zones that keep them, as the system time zone database has
    /// it. Rule changes, such as British Columbia's permanent daylight time,
    /// arrive with iOS updates.
    func formattedTime(for date: Date, locale: Locale = .autoupdatingCurrent) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened).locale(locale)
        style.timeZone = self.timeZone
        let time = date.formatted(style)
        let offset = self.timeZone.gmtOffsetLabel(at: date, locale: locale)
        return "\(time) (\(offset))"
    }
}
