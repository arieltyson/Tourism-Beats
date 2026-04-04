import SwiftUI

// MARK: - WorldSearchDock

struct WorldSearchDock: View {
    @Binding var searchText: String

    let results: [CityModel]
    let isPresented: Bool
    let onSelect: (CityModel) -> Void
    let onSubmit: () -> Void
    let onClear: () -> Void
    let searchFieldFocus: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            if self.isPresented {
                self.resultsPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: SpacingTokens.small) {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.secondaryLabel)
                    .accessibilityHidden(true)

                TextField("Search cities or countries", text: self.$searchText)
                    .font(TypographyTokens.body)
                    .foregroundStyle(AppColors.label)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .focused(self.searchFieldFocus)
                    .onSubmit {
                        self.onSubmit()
                    }

                if !self.searchText.isEmpty {
                    Button {
                        self.onClear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(AppColors.secondaryLabel)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, SpacingTokens.medium)
            .padding(.vertical, SpacingTokens.small)
            .background(
                .ultraThinMaterial,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
        }
        .padding(.bottom, SpacingTokens.xSmall)
        .animation(.easeInOut(duration: 0.22), value: self.isPresented)
    }

    private var resultsPanel: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            Text(self.resultsPanelTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.secondaryLabel)
                .padding(.horizontal, SpacingTokens.xSmall)

            if self.results.isEmpty {
                Text("No cities or countries match \"\(self.searchText)\"")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(AppColors.secondaryLabel)
                    .padding(.horizontal, SpacingTokens.medium)
                    .padding(.vertical, SpacingTokens.small)
            } else {
                ScrollView {
                    LazyVStack(spacing: SpacingTokens.xSmall) {
                        ForEach(self.results, id: \.id) { city in
                            Button {
                                self.onSelect(city)
                            } label: {
                                CitySearchResultRow(
                                    city: city,
                                    searchText: self.searchText
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, SpacingTokens.xSmall)
                    .padding(.vertical, SpacingTokens.xSmall)
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: 280)
            }
        }
        .padding(.top, SpacingTokens.xSmall)
        .padding(.bottom, SpacingTokens.small)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 16, y: 8)
    }

    private var resultsPanelTitle: String {
        let query = self.searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? "Suggested destinations" : "Matching destinations"
    }
}
