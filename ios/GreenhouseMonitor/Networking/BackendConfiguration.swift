import Foundation

/// Where the live backend lives and who is calling it, read from `Resources/Backend.plist`.
struct BackendConfiguration: Equatable, Sendable {
    let baseURL: URL
    /// The candidate's email address, sent as the `X-Candidate-Token` header.
    let candidateEmail: String

    enum Setup: Equatable, Sendable {
        case configured(BackendConfiguration)
        /// The app falls back to the in-process mock and shows `reason` to the user.
        case notConfigured(reason: String)
    }

    static func load(from bundle: Bundle = .main) -> Setup {
        guard
            let url = bundle.url(forResource: "Backend", withExtension: "plist"),
            let values = NSDictionary(contentsOf: url) as? [String: Any]
        else {
            return .notConfigured(reason: String(localized: "Backend.plist is missing from the app bundle."))
        }
        return parse(values)
    }

    static func parse(_ values: [String: Any]) -> Setup {
        let baseURLString = (values["BaseURL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let baseURL = URL(string: baseURLString), baseURL.scheme == "https", baseURL.host() != nil else {
            return .notConfigured(reason: String(localized: "BaseURL in Backend.plist is not a valid https URL."))
        }

        let email = (values["CandidateEmail"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !email.isEmpty else {
            return .notConfigured(reason: String(localized: "Set CandidateEmail in ios/GreenhouseMonitor/Resources/Backend.plist to the email address you applied with."))
        }
        guard isPlausibleEmail(email) else {
            return .notConfigured(reason: String(localized: "CandidateEmail \"\(email)\" in Backend.plist is not a valid email address."))
        }

        return .configured(BackendConfiguration(baseURL: baseURL, candidateEmail: email))
    }

    private static func isPlausibleEmail(_ value: String) -> Bool {
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".") && !value.contains(" ")
    }
}
