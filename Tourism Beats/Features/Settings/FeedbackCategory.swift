import Foundation

// MARK: - FeedbackCategory

/// Categories supported by the in-app feedback flow.
enum FeedbackCategory: String, Identifiable, Sendable {
    case bug
    case feature

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .bug: "Report a Bug"
        case .feature: "Suggest a Feature"
        }
    }

    var systemImage: String {
        switch self {
        case .bug: "ladybug"
        case .feature: "lightbulb"
        }
    }

    var summary: String {
        switch self {
        case .bug:
            "Describe what happened, what you expected, and how to reproduce it."
        case .feature:
            "Share the improvement you want and how it would help your trips."
        }
    }

    var placeholder: String {
        switch self {
        case .bug:
            "What were you doing, what went wrong, and what did you expect instead?"
        case .feature:
            "What feature would you like to see, and how would you use it?"
        }
    }

    var emailSubject: String {
        switch self {
        case .bug: "Tourism Beats Bug Report"
        case .feature: "Tourism Beats Feature Suggestion"
        }
    }

    var accessibilityInputLabels: [String] {
        switch self {
        case .bug:
            ["Report a Bug", "Bug Report", "Report Bug"]
        case .feature:
            ["Suggest a Feature", "Feature Suggestion", "Suggest Feature"]
        }
    }
}
