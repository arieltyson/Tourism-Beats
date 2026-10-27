import SwiftUI

// MARK: - CityFunFactSheet

/// The whole of a fun fact the card could only preview, with its source.
///
/// Opens at half height, which fits most facts, and can be pulled up for the
/// longest ones; the text scrolls and can be selected to copy.
struct CityFunFactSheet: View {
    let fact: CityFunFact

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                    Text(self.fact.text)
                        .font(TypographyTokens.body)
                        .foregroundStyle(AppColors.label)
                        .textSelection(.enabled)

                    if let sourceURL = self.fact.sourceURL {
                        Link("Source: \(self.fact.sourceName)", destination: sourceURL)
                            .font(TypographyTokens.footnote)
                            .foregroundStyle(AppColors.secondaryLabel)
                    } else {
                        Text("Source: \(self.fact.sourceName)")
                            .font(TypographyTokens.footnote)
                            .foregroundStyle(AppColors.secondaryLabel)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SpacingTokens.medium)
            }
            .navigationTitle("Fun Fact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        self.dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // City pages are always dark and pass that down to this sheet, but an
        // expanded sheet otherwise draws its opaque background in the system
        // appearance, leaving light text on a light sheet.
        .preferredColorScheme(.dark)
    }
}
