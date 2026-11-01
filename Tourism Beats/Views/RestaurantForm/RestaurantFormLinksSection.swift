import SwiftUI

// MARK: - RestaurantFormLinksSection

/// Map and menu links, with inline validation.
struct RestaurantFormLinksSection: View {
    @Binding var locationURLString: String
    @Binding var menuURLString: String
    let locationValidationMessage: String?
    let menuValidationMessage: String?
    var focusedField: FocusState<RestaurantFormField?>.Binding

    var body: some View {
        Section {
            TextField("Apple Maps or Google Maps link", text: self.$locationURLString)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .textContentType(.URL)
                .autocorrectionDisabled()
                .focused(self.focusedField, equals: .locationLink)
                .submitLabel(.next)
                .onSubmit {
                    self.focusedField.wrappedValue = .menuLink
                }

            if let locationValidationMessage {
                Text(locationValidationMessage)
                    .font(TypographyTokens.footnote)
                    .foregroundStyle(AppColors.danger)
            }

            TextField("Menu link", text: self.$menuURLString)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .textContentType(.URL)
                .autocorrectionDisabled()
                .focused(self.focusedField, equals: .menuLink)
                .submitLabel(.done)

            if let menuValidationMessage {
                Text(menuValidationMessage)
                    .font(TypographyTokens.footnote)
                    .foregroundStyle(AppColors.danger)
            }
        } header: {
            Text("Links")
        } footer: {
            Text("Paste full links, or just the site address, and the app will normalize them.")
        }
    }
}
