import SwiftUI

// MARK: - TripStaySearchStatus

/// Stands in for the results while there are none to show.
struct TripStaySearchStatus: View {
    let model: TripStaySearchViewModel

    var body: some View {
        if self.model.isSearching {
            ProgressView()
        } else if self.model.didFail {
            ContentUnavailableView(
                "Hotels Unavailable",
                systemImage: "wifi.exclamationmark",
                description: Text("Check your connection and try again.")
            )
        } else {
            ContentUnavailableView.search(text: self.model.trimmedQuery)
        }
    }
}
