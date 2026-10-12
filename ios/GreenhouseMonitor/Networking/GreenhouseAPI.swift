import Foundation

/// Remote API for the greenhouse backend.
///
/// Implemented by `LiveGreenhouseAPI` (the real HTTP service) and `MockGreenhouseAPI` (an in-process
/// fake used by tests and when no backend is configured). Treat both as black boxes.
protocol GreenhouseAPI: Sendable {
    func fetchSensors() async throws -> [Sensor]

    /// Returns readings for `sensorId` with a timestamp strictly after `since`, oldest first.
    /// Pass `nil` to receive everything inside the server's retention window.
    func fetchReadings(sensorId: String, since: Date?) async throws -> [Reading]

    /// Uploads a care log entry.
    ///
    /// The server treats `entry.id` as an idempotency key: posting the same id more than once
    /// stores the entry only once and returns the original receipt.
    func postCareLog(_ entry: CareLogUpload) async throws -> CareLogReceipt
}

/// Lets callers observe whether the backend is reachable.
protocol ConnectivityMonitoring: Sendable {
    var isOnline: Bool { get async }

    /// Emits the current state immediately, then every change.
    func onlineUpdates() async -> AsyncStream<Bool>
}

struct CareLogUpload: Codable, Hashable, Sendable {
    /// Client-generated identifier. Also used by the server as the idempotency key.
    let id: String
    let sensorId: String
    /// One of `watered`, `fertilised`, `moved`, `other`.
    let kind: String
    let note: String?
    let createdAt: Date
}

struct CareLogReceipt: Codable, Hashable, Sendable {
    let id: String
    let serverId: Int
    let receivedAt: Date
}

enum APIError: Error, Equatable, LocalizedError {
    case offline
    case timeout
    case serverError(statusCode: Int)
    case unknownSensor(String)
    /// The backend did not accept the candidate email (missing, malformed or not registered).
    case notAuthorized
    case rejected(statusCode: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .offline:
            String(localized: "You appear to be offline.")
        case .timeout:
            String(localized: "The request timed out.")
        case .serverError(let statusCode):
            String(localized: "The server returned an error (\(statusCode)).")
        case .unknownSensor:
            String(localized: "The sensor could not be found.")
        case .notAuthorized:
            String(localized: "The server did not accept your email address. Check CandidateEmail in Backend.plist.")
        case .rejected(let statusCode):
            String(localized: "The server rejected the request (\(statusCode)).")
        case .invalidResponse:
            String(localized: "The server sent an unexpected response.")
        }
    }
}
