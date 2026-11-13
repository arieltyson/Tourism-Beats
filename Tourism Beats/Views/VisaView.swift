// VisaView.swift
// Tourism Beats
//
// Displays visa requirement data with a passport picker
// inside the parent AdvisoryCard's glass container. The page
// presents the picker, so a change of layout can't dismiss it.

import SwiftUI

// MARK: - VisaView

struct VisaView: View {
    @Bindable var viewModel: VisaViewModel
    @Binding var showingCountryPicker: Bool

    private let allCountries: [CountryModel] =
        (try? DataService().loadCountries()) ?? []

    private var currentCountry: CountryModel? {
        self.allCountries.first { $0.code == self.viewModel.passportCode }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.medium) {
            VisaPassportPicker(
                currentCountry: self.currentCountry,
                showingPicker: self.$showingCountryPicker
            )

            VisaRequirementBadge(
                isAwaitingRequirement: self.viewModel.isAwaitingRequirement,
                errorMessage: self.viewModel.errorMessage,
                summaryText: self.viewModel.summaryText,
                requirementColor: self.viewModel.requirementColor,
                hasRequirement: self.viewModel.requirement != nil
            )

            VisaDisclaimer()
        }
    }
}

// MARK: - VisaDisclaimer

private struct VisaDisclaimer: View {
    var body: some View {
        Label("Visa requirements change often. Always verify.", systemImage: "info.circle")
            .font(TypographyTokens.caption)
            .foregroundStyle(.secondary)
    }
}

// MARK: - VisaPassportPicker

private struct VisaPassportPicker: View {
    let currentCountry: CountryModel?
    @Binding var showingPicker: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            Button {
                self.showingPicker = true
            } label: {
                HStack(spacing: SpacingTokens.xSmall) {
                    if let country = self.currentCountry {
                        Text("\(country.flag) \(country.name)")
                            .foregroundStyle(.primary)
                    } else {
                        Text("Select Country")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(TypographyTokens.caption)
                        .foregroundStyle(.secondary)
                }
                .font(TypographyTokens.cardLabel)
                .padding(.vertical, SpacingTokens.xSmall)
                .padding(.horizontal, SpacingTokens.small)
                .background(
                    .ultraThinMaterial,
                    in: Capsule(style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select passport country")
            .accessibilityValue(self.currentCountry?.name ?? "None selected")
            .accessibilityHint("Opens the list of passport countries")
            .accessibilityInputLabels(["Passport Country", "Select Passport Country"])
        }
    }
}

// MARK: - VisaRequirementBadge

private struct VisaRequirementBadge: View {
    let isAwaitingRequirement: Bool
    let errorMessage: String?
    let summaryText: String
    let requirementColor: Color
    let hasRequirement: Bool

    var body: some View {
        if self.isAwaitingRequirement {
            // The status capsule, redacted, so the card keeps its size.
            VisaStatusCapsule(
                systemImage: "checkmark.circle.fill",
                text: "Visa-free for 90 days",
                color: .secondary
            )
            .redacted(reason: .placeholder)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading visa requirements")
        } else if self.errorMessage != nil {
            Label {
                Text("Could not load visa requirements.")
                    .font(TypographyTokens.caption)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .foregroundStyle(.secondary)
        } else if self.hasRequirement {
            VisaStatusCapsule(
                systemImage: self.statusIcon,
                text: self.summaryText,
                color: self.requirementColor
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Visa status: \(self.summaryText)")
        } else {
            Label("No visa information for this passport and destination", systemImage: "info.circle")
                .font(TypographyTokens.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusIcon: String {
        let text = self.summaryText.lowercased()
        if text.localizedStandardContains("welcome") {
            return "house.fill"
        } else if text.localizedStandardContains("free") {
            return "checkmark.circle.fill"
        } else if text.localizedStandardContains("not permitted") {
            return "xmark.circle.fill"
        } else if text.localizedStandardContains("required") {
            return "doc.text.fill"
        } else {
            return "info.circle.fill"
        }
    }
}

// MARK: - VisaStatusCapsule

/// The visa status as a tinted capsule.
private struct VisaStatusCapsule: View {
    let systemImage: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: SpacingTokens.xSmall) {
            Image(systemName: self.systemImage)
                .font(TypographyTokens.caption)

            Text(self.text)
                .font(TypographyTokens.cardLabel.weight(.semibold))
        }
        .foregroundStyle(self.color)
        .padding(.vertical, SpacingTokens.xSmall)
        .padding(.horizontal, SpacingTokens.small)
        .background(self.color.opacity(0.12), in: .capsule)
    }
}
