import SwiftUI

// MARK: - RestaurantFormChoiceLink

/// A form row showing a chosen value that opens a list to change it.
struct RestaurantFormChoiceLink: View {
    let title: String
    let value: String
    let route: RestaurantFormRoute

    var body: some View {
        NavigationLink(value: self.route) {
            LabeledContent(self.title, value: self.value)
        }
        .accessibilityLabel(self.title)
        .accessibilityValue(self.value)
    }
}
