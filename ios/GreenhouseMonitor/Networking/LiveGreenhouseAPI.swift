import Foundation

/// `GreenhouseAPI` backed by the real HTTP service.
///
/// Latency and failures are simulated by the server (sent as request headers); "offline" is
/// simulated on the device by failing requests before they are sent.
actor LiveGreenhouseAPI: BackendClient {
    private(set) var configuration: SimulationConfiguration

    private let backend: BackendConfiguration
    private let session: URLSession
    private let onlineStatus = OnlineStatusBroadcaster()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    init(backend: BackendConfiguration, configuration: SimulationConfiguration = SimulationConfiguration(), session: URLSession = .shared) {
        self.backend = backend
        self.configuration = configuration
        self.session = session
    }

    // MARK: - GreenhouseAPI

    func fetchSensors() async throws -> [Sensor] {
        try await send(path: "v1/sensors")
    }

    func fetchReadings(sensorId: String, since: Date?) async throws -> [Reading] {
        let query = since.map { [URLQueryItem(name: "since", value: $0.formatted(.iso8601))] } ?? []
        return try await send(path: "v1/sensors/\(sensorId)/readings", query: query, sensorId: sensorId)
    }

    func postCareLog(_ entry: CareLogUpload) async throws -> CareLogReceipt {
        try await send(path: "v1/care-logs", method: "POST", body: try encoder.encode(entry), sensorId: entry.sensorId)
    }

    // MARK: - ConnectivityMonitoring

    var isOnline: Bool {
        !configuration.isOffline
    }

    func onlineUpdates() -> AsyncStream<Bool> {
        onlineStatus.stream(initialValue: !configuration.isOffline)
    }

    // MARK: - SimulationControlling

    func updateConfiguration(_ newValue: SimulationConfiguration) {
        let connectivityChanged = newValue.isOffline != configuration.isOffline
        configuration = newValue
        if connectivityChanged {
            onlineStatus.broadcast(!newValue.isOffline)
        }
    }

    func serverStats() async throws -> ServerStats {
        try await send(path: "v1/stats", simulated: false)
    }

    func resetServer() async throws {
        _ = try await perform(path: "v1/reset", method: "POST", simulated: false)
    }

    // MARK: - Transport

    private struct ErrorBody: Decodable {
        let error: String
    }

    private func send<Response: Decodable>(
        path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Data? = nil,
        sensorId: String? = nil,
        simulated: Bool = true
    ) async throws -> Response {
        let data = try await perform(path: path, method: method, query: query, body: body, sensorId: sensorId, simulated: simulated)
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func perform(
        path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Data? = nil,
        sensorId: String? = nil,
        simulated: Bool = true
    ) async throws -> Data {
        if simulated && configuration.isOffline {
            throw APIError.offline
        }

        var url = backend.baseURL.appending(path: path)
        if !query.isEmpty {
            url.append(queryItems: query)
        }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = method
        request.httpBody = body
        request.setValue(backend.candidateEmail, forHTTPHeaderField: "X-Candidate-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if simulated {
            request.setValue(String(configuration.latency.milliseconds), forHTTPHeaderField: "X-Simulate-Latency-Ms")
            request.setValue(String(configuration.failureRate), forHTTPHeaderField: "X-Simulate-Failure-Rate")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw Self.map(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let code = try? decoder.decode(ErrorBody.self, from: data).error
            throw Self.map(statusCode: http.statusCode, errorCode: code, sensorId: sensorId)
        }
        return data
    }

    private static func map(_ error: URLError) -> Error {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .cannotFindHost, .cannotConnectToHost:
            APIError.offline
        case .timedOut:
            APIError.timeout
        default:
            error
        }
    }

    private static func map(statusCode: Int, errorCode: String?, sensorId: String?) -> APIError {
        switch (statusCode, errorCode) {
        case (404, "unknown_sensor"):
            .unknownSensor(sensorId ?? "")
        case (401, _), (403, _):
            .notAuthorized
        case (504, _):
            .timeout
        case (500..., _):
            .serverError(statusCode: statusCode)
        default:
            .rejected(statusCode: statusCode)
        }
    }
}
