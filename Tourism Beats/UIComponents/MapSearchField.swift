import SwiftUI

// MARK: - MapSearchField

/// A glass search field that floats over the map within thumb reach.
///
/// It's a real text field rather than a button that opens a search screen,
/// so a tap focuses it at once and it rides up on the keyboard in one
/// motion. While searching, a close button morphs out of its glass.
struct MapSearchField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let isSearching: Bool
    let onClose: () -> Void

    @Namespace private var glassNamespace

    var body: some View {
        GlassEffectContainer(spacing: SpacingTokens.small) {
            HStack(spacing: SpacingTokens.small) {
                HStack(spacing: SpacingTokens.xSmall) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)

                    TextField("Search cities or countries", text: self.$text)
                        .focused(self.isFocused)
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)

                    if !self.text.isEmpty {
                        Button("Clear", systemImage: "xmark.circle.fill") {
                            self.text = ""
                        }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.secondary)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, SpacingTokens.medium)
                .frame(minHeight: SpacingTokens.minimumTapTarget)
                .contentShape(.capsule)
                .glassEffect(.regular.interactive(), in: .capsule)
                .glassEffectID("field", in: self.glassNamespace)

                if self.isSearching {
                    Button("Close", systemImage: "xmark", role: .close, action: self.onClose)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .controlSize(.large)
                        .glassEffectID("close", in: self.glassNamespace)
                }
            }
        }
    }
}
