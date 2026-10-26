import SwiftUI

// MARK: - TripSuggestionRequest

/// Identifies one presentation of the suggestions sheet.
struct TripSuggestionRequest: Identifiable {
    let id = UUID()
    let city: CityModel
    let scope: TripSuggestionsViewModel.Scope
}
