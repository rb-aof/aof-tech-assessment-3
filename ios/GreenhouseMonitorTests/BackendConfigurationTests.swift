import Foundation
import Testing
@testable import GreenhouseMonitor

struct BackendConfigurationTests {
    private let baseURL = "https://backend.example"

    @Test func latencyIsConvertedToWholeMilliseconds() {
        #expect(Duration.milliseconds(1200).milliseconds == 1200)
        #expect(Duration.seconds(2.5).milliseconds == 2500)
        #expect(Duration.zero.milliseconds == 0)
    }

    @Test func validConfigurationIsAccepted() {
        let setup = BackendConfiguration.parse(["BaseURL": baseURL, "CandidateEmail": " ana@example.com "])

        #expect(setup == .configured(BackendConfiguration(baseURL: URL(string: baseURL)!, candidateEmail: "ana@example.com")))
    }

    @Test(arguments: ["", "   ", "ana", "ana@example", "@example.com", "ana @example.com"])
    func missingOrInvalidEmailIsReported(email: String) {
        guard case .notConfigured(let reason) = BackendConfiguration.parse(["BaseURL": baseURL, "CandidateEmail": email]) else {
            Issue.record("Expected .notConfigured for \(email.debugDescription)")
            return
        }
        #expect(reason.contains("CandidateEmail"))
    }

    @Test func invalidBaseURLIsReported() {
        let setup = BackendConfiguration.parse(["BaseURL": "not a url", "CandidateEmail": "ana@example.com"])

        guard case .notConfigured(let reason) = setup else {
            Issue.record("Expected .notConfigured")
            return
        }
        #expect(reason.contains("BaseURL"))
    }

    @Test func bundledPlistPointsAtTheBackend() {
        // The shipped plist must have a BaseURL; the email is intentionally left for the candidate.
        let setup = BackendConfiguration.load()
        if case .notConfigured(let reason) = setup {
            #expect(!reason.contains("BaseURL"))
        }
    }
}
