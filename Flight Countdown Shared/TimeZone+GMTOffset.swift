import Foundation

extension TimeZone {
    /// The offset from GMT in effect at `date`, such as "GMT-7" or "GMT+5:30",
    /// in the person's locale.
    ///
    /// The offset comes from the system time zone database at that moment,
    /// not today's, so a December flight shows December's offset. When a
    /// region changes its rules, as British Columbia did by adopting permanent
    /// daylight time, the label follows as soon as iOS updates its database.
    func gmtOffsetLabel(at date: Date) -> String {
        var style = Date.FormatStyle().timeZone(.localizedGMT(.short))
        style.timeZone = self
        return date.formatted(style)
    }

    /// The place a time zone is named after, such as "Buenos Aires" for
    /// `America/Argentina/Buenos_Aires`.
    var cityName: String {
        (identifier.split(separator: "/").last.map(String.init) ?? identifier).replacing("_", with: " ")
    }
}
