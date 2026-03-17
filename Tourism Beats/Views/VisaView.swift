// VisaView.swift
// Tourism Beats
//
// Displays visa requirement data with a passport picker
// inside the parent AdvisoryCard's glass container.

import SwiftUI

// MARK: - VisaView

struct VisaView: View {
    @StateObject var viewModel: VisaViewModel
    @State private var showingCountryPicker = false

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
            .sheet(isPresented: self.$showingCountryPicker) {
                SearchableCountryPicker(
                    selectedCode: self.$viewModel.passportCode
                )
            }
            .onChange(of: self.viewModel.passportCode) { _, newValue in
                self.viewModel.updatePassport(to: newValue)
            }

            VisaRequirementBadge(
                isLoading: self.viewModel.isLoading,
                errorMessage: self.viewModel.errorMessage,
                summaryText: self.viewModel.summaryText,
                requirementColor: self.viewModel.requirementColor,
                hasRequirement: self.viewModel.requirement != nil
            )
        }
    }
}

// MARK: - VisaPassportPicker

private struct VisaPassportPicker: View {
    let currentCountry: CountryModel?
    @Binding var showingPicker: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            Text("Your Passport")
                .font(TypographyTokens.footnote)
                .foregroundStyle(.secondary)

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
    let isLoading: Bool
    let errorMessage: String?
    let summaryText: String
    let requirementColor: Color
    let hasRequirement: Bool

    var body: some View {
        Group {
            if self.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                    .frame(maxWidth: .infinity, minHeight: 36)
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
                HStack(spacing: SpacingTokens.xSmall) {
                    Image(systemName: self.statusIcon)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(self.requirementColor)

                    Text(self.summaryText)
                        .font(TypographyTokens.cardLabel.weight(.semibold))
                        .foregroundStyle(self.requirementColor)
                }
                .padding(.vertical, SpacingTokens.xSmall)
                .padding(.horizontal, SpacingTokens.small)
                .background(
                    self.requirementColor.opacity(0.12),
                    in: Capsule(style: .continuous)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Visa status: \(self.summaryText)")
            } else {
                Text("No visa information available.")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusIcon: String {
        let text = self.summaryText.lowercased()
        if text.localizedStandardContains("welcome") {
            return "house.fill"
        } else if text.localizedStandardContains("free") {
            return "checkmark.circle.fill"
        } else if text.localizedStandardContains("banned") {
            return "xmark.circle.fill"
        } else if text.localizedStandardContains("required") {
            return "doc.text.fill"
        } else {
            return "info.circle.fill"
        }
    }
}
