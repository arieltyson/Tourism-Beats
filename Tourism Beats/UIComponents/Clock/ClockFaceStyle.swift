import SwiftUI

// MARK: - ClockFaceStyle

/// The colors of the clock's face for the time of day and contrast setting.
struct ClockFaceStyle: Equatable {
    /// The dial behind everything.
    let face: Color

    /// The numerals, hour and minute hands, and their hub.
    let ink: Color

    /// The minute ticks.
    let ticks: Color

    /// The second hand and its cap, in the app's accent.
    let accent: Color

    init(phase: ClockFacePhase, contrast: ColorSchemeContrast) {
        let ink: Color = phase == .day ? .black : .white
        let tickOpacity = contrast == .increased
            ? ClockFaceTokens.increasedContrastTickOpacity
            : ClockFaceTokens.tickOpacity

        self.face = phase == .day ? .white : .black
        self.ink = ink
        self.ticks = ink.opacity(tickOpacity)
        self.accent = AppColors.accent
    }
}
