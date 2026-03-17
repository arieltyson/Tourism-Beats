import SwiftUI

// MARK: - FeedbackView

struct FeedbackView: View {
    let category: FeedbackCategory

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @FocusState private var isEditorFocused: Bool
    @State private var messageBody = ""
    @State private var errorMessage: String?

    private var composer: FeedbackMailComposer {
        FeedbackMailComposer(
            category: self.category,
            message: self.messageBody
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SpacingTokens.large) {
                    FeedbackHeroCard(category: self.category)

                    FeedbackEditorCard(
                        messageBody: self.$messageBody,
                        isEditorFocused: self.$isEditorFocused,
                        placeholder: self.category.placeholder
                    )

                    FeedbackContextCard(contextLines: self.composer.contextLines)
                }
                .padding(.horizontal, SpacingTokens.medium)
                .padding(.vertical, SpacingTokens.large)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColors.surface.ignoresSafeArea())
            .navigationTitle(self.category.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Send", systemImage: "paperplane.fill") {
                        self.sendFeedback()
                    }
                    .disabled(self.isSendDisabled)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        self.isEditorFocused = false
                    }
                }
            }
        }
        .alert(
            "Couldn't Open Mail",
            isPresented: self.errorPresented
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.errorMessage ?? "Please try again in a moment.")
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { self.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    self.errorMessage = nil
                }
            }
        )
    }

    private var isSendDisabled: Bool {
        self.messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendFeedback() {
        guard let mailURL = self.composer.mailURL else {
            self.errorMessage =
                "Mail isn't available right now. You can contact \(FeedbackMailComposer.supportEmail) directly."
            return
        }

        self.openURL(mailURL) { accepted in
            if accepted {
                self.dismiss()
            } else {
                self.errorMessage =
                    "Mail isn't available right now. You can contact \(FeedbackMailComposer.supportEmail) directly."
            }
        }
    }
}

// MARK: - FeedbackHeroCard

private struct FeedbackHeroCard: View {
    let category: FeedbackCategory

    var body: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                HStack(alignment: .top, spacing: SpacingTokens.small) {
                    Image(systemName: self.category.systemImage)
                        .font(.title2)
                        .foregroundStyle(self.iconTint)
                        .padding(SpacingTokens.small)
                        .background(
                            self.iconTint.opacity(0.16),
                            in: .rect(cornerRadius: 16, style: .continuous)
                        )
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                        Text(self.category.title)
                            .font(TypographyTokens.songTitle)
                            .bold()
                            .foregroundStyle(AppColors.label)

                        Text(self.category.summary)
                            .font(TypographyTokens.body)
                            .foregroundStyle(AppColors.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text(
                    "Tourism Beats opens Mail with your message, app version, device model, and iOS version prefilled."
                )
                .font(TypographyTokens.footnote)
                .foregroundStyle(AppColors.secondaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
    }

    private var iconTint: Color {
        switch self.category {
        case .bug: AppColors.coral
        case .feature: AppColors.info
        }
    }
}

// MARK: - FeedbackEditorCard

private struct FeedbackEditorCard: View {
    @Binding var messageBody: String
    var isEditorFocused: FocusState<Bool>.Binding
    let placeholder: String

    var body: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Text("Message")
                    .font(TypographyTokens.sectionHeader)
                    .foregroundStyle(AppColors.label)

                ZStack(alignment: .topLeading) {
                    if self.messageBody.isEmpty {
                        Text(self.placeholder)
                            .font(TypographyTokens.body)
                            .foregroundStyle(AppColors.secondaryLabel)
                            .padding(.horizontal, SpacingTokens.small)
                            .padding(.vertical, SpacingTokens.small)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: self.$messageBody)
                        .font(TypographyTokens.body)
                        .foregroundStyle(AppColors.label)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 180)
                        .focused(self.isEditorFocused)
                        .accessibilityLabel("Feedback message")
                }
                .padding(SpacingTokens.xxSmall)
                .background(
                    AppColors.surfaceSecondary,
                    in: .rect(cornerRadius: 18, style: .continuous)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - FeedbackContextCard

private struct FeedbackContextCard: View {
    let contextLines: [String]

    var body: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Text("Attached Context")
                    .font(TypographyTokens.sectionHeader)
                    .foregroundStyle(AppColors.label)

                Text(
                    "These details are included automatically so reports are easier to triage."
                )
                .font(TypographyTokens.body)
                .foregroundStyle(AppColors.secondaryLabel)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    ForEach(self.contextLines, id: \.self) { line in
                        Text(line)
                            .font(TypographyTokens.caption.monospaced())
                            .foregroundStyle(AppColors.label)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(SpacingTokens.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    AppColors.surfaceSecondary,
                    in: .rect(cornerRadius: 18, style: .continuous)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
