import SwiftUI

// MARK: - RestaurantFormIdentitySection

/// The restaurant's name and where it is. City and country open searchable lists.
struct RestaurantFormIdentitySection: View {
    @Binding var name: String
    let city: String
    let country: String
    var focusedField: FocusState<RestaurantFormField?>.Binding

    var body: some View {
        Section("Restaurant") {
            TextField("Restaurant Name", text: self.$name)
                .textContentType(.organizationName)
                .autocorrectionDisabled()
                .focused(self.focusedField, equals: .name)
                .submitLabel(.done)

            RestaurantFormChoiceLink(title: "City", value: self.city, route: .city)
            RestaurantFormChoiceLink(title: "Country", value: self.country, route: .country)
        }
    }
}
