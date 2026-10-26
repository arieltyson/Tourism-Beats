import SwiftUI

// MARK: - RestaurantFormCitySuggestions

/// Cities already in the journal that match what has been typed.
struct RestaurantFormCitySuggestions: View {
    let suggestions: [String]
    @Binding var city: String
    @Binding var isPresented: Bool

    var body: some View {
        ForEach(self.suggestions, id: \.self) { suggestion in
            Button {
                self.city = suggestion
                self.isPresented = false
            } label: {
                HStack(spacing: SpacingTokens.xSmall) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(suggestion)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
