import Foundation
import UIKit

// MARK: - FeedbackMailComposer

/// Builds the support email URL and attached device context for feedback.
@MainActor
struct FeedbackMailComposer {
    static let supportEmail = "arieltyson30190@gmail.com"

    let category: FeedbackCategory
    let message: String

    var mailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: self.category.emailSubject),
            URLQueryItem(name: "body", value: self.emailBody)
        ]
        return components.url
    }

    var contextLines: [String] {
        let shortVersion =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as? String ?? "Unknown"
        let buildNumber =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
            as? String ?? "Unknown"
        let systemName = UIDevice.current.systemName
        let systemVersion = UIDevice.current.systemVersion

        return [
            "App Version: \(shortVersion) (\(buildNumber))",
            "Device: \(self.deviceIdentifier)",
            "System: \(systemName) \(systemVersion)"
        ]
    }

    private var emailBody: String {
        """
        \(self.normalizedMessage)

        ---
        \(self.contextLines.joined(separator: "\n"))
        """
    }

    private var normalizedMessage: String {
        self.message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var deviceIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machine = Mirror(reflecting: systemInfo.machine).children.reduce(into: "") {
            partialResult,
            element in
            guard let value = element.value as? Int8, value != 0 else { return }
            partialResult.append(Character(UnicodeScalar(UInt8(value))))
        }

        return machine.isEmpty ? UIDevice.current.model : machine
    }
}
