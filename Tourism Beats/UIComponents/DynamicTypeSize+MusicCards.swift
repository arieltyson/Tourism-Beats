import SwiftUI

extension DynamicTypeSize {
    var prefersMusicCardVerticalLayout: Bool {
        self >= .xxxLarge
    }

    /// The most lines a player card gives its song title and artist name.
    ///
    /// The cards repeat the song named in full just above them, so at standard
    /// sizes each line truncates instead of wrapping. That keeps every song's
    /// cards one height, and the page fits the pager. The stacked layout used
    /// at larger sizes has room to wrap, so text there is never cut short.
    /// VoiceOver reads the full title either way.
    var musicCardTextLineLimit: Int? {
        self.prefersMusicCardVerticalLayout ? nil : 1
    }
}
