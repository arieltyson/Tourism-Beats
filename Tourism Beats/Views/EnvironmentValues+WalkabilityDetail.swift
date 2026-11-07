import SwiftUI

extension EnvironmentValues {
    /// Whether the walkability tiles show the sentence explaining each score.
    ///
    /// Each tile already names its rating, such as "Somewhat Walkable", so the
    /// sentence beneath only expands on it. A page short on room hides it so
    /// the page fits without scrolling. VoiceOver reads it either way.
    @Entry var showsWalkabilityDetail = true
}
