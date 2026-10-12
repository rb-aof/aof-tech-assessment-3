import Foundation
import Testing
@testable import GreenhouseMonitor

/// Intercepts requests made through `StubURLProtocol.session` and answers with `handler`.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (Int, Data)

    private static let state = Locked<(handler: Handler?, requests: [URLRequest])>((nil, []))

    static var session: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func respond(with handler: @escaping Handler) {
        state.withLock { $0 = (handler, []) }
    }

    static var requests: [URLRequest] {
        state.withLock { $0.requests }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        var request = request
        // URLSession moves small bodies into a stream; read it back so handlers can inspect it.
        if request.httpBody == nil, let stream = request.httpBodyStream {
            stream.open()
            var body = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                body.append(buffer, count: count)
            }
            stream.close()
            request.httpBody = body
        }

        let handler = Self.state.withLock { state in
            state.requests.append(request)
            return state.handler
        }
        do {
            guard let handler else { throw URLError(.unsupportedURL) }
            let (status, data) = try handler(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
}

@Suite(.serialized)
struct LiveGreenhouseAPITests {
    private let backend = BackendConfiguration(baseURL: URL(string: "https://backend.example")!, candidateEmail: "ana@example.com")

    private func makeAPI(_ configuration: SimulationConfiguration = SimulationConfiguration(latency: .milliseconds(1200), failureRate: 0.3)) -> LiveGreenhouseAPI {
        LiveGreenhouseAPI(backend: backend, configuration: configuration, session: StubURLProtocol.session)
    }

    @Test func sendsTokenAndSimulationHeaders() async throws {
        StubURLProtocol.respond { _ in (200, Data(#"[{"id":"s-1","name":"Bench 1","zone":"North","plant":"Basil"}]"#.utf8)) }

        let sensors = try await makeAPI().fetchSensors()

        #expect(sensors == [Sensor(id: "s-1", name: "Bench 1", zone: "North", plant: "Basil")])
        let request = try #require(StubURLProtocol.requests.first)
        #expect(request.url?.absoluteString == "https://backend.example/v1/sensors")
        #expect(request.value(forHTTPHeaderField: "X-Candidate-Token") == "ana@example.com")
        #expect(request.value(forHTTPHeaderField: "X-Simulate-Latency-Ms") == "1200")
        #expect(request.value(forHTTPHeaderField: "X-Simulate-Failure-Rate") == "0.3")
    }

    @Test func readingsSendSinceAndDecodeDates() async throws {
        StubURLProtocol.respond { _ in
            (200, Data(#"[{"id":"s-1-1","sensorId":"s-1","timestamp":"2026-01-15T12:00:00Z","soilMoisture":41.5,"temperature":21.2,"humidity":63}]"#.utf8))
        }
        let since = Date(timeIntervalSince1970: 1_768_478_340) // 2026-01-15T11:59:00Z

        let readings = try await makeAPI().fetchReadings(sensorId: "s-1", since: since)

        #expect(readings.first?.timestamp == Date(timeIntervalSince1970: 1_768_478_400))
        let url = try #require(StubURLProtocol.requests.first?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/v1/sensors/s-1/readings")
        #expect(components.queryItems == [URLQueryItem(name: "since", value: "2026-01-15T11:59:00Z")])
    }

    @Test func postsCareLogAsJSON() async throws {
        StubURLProtocol.respond { _ in (201, Data(#"{"id":"log-1","serverId":7,"receivedAt":"2026-01-15T12:00:30Z"}"#.utf8)) }
        let entry = CareLogUpload(id: "log-1", sensorId: "s-1", kind: "watered", note: nil, createdAt: Date(timeIntervalSince1970: 1_768_478_340))

        let receipt = try await makeAPI().postCareLog(entry)

        #expect(receipt.serverId == 7)
        let request = try #require(StubURLProtocol.requests.first)
        #expect(request.httpMethod == "POST")
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["id"] as? String == "log-1")
        #expect(json["createdAt"] as? String == "2026-01-15T11:59:00Z")
    }

    @Test(arguments: [
        (503, #"{"error":"service_unavailable"}"#, APIError.serverError(statusCode: 503)),
        (504, #"{"error":"timeout"}"#, APIError.timeout),
        (404, #"{"error":"unknown_sensor"}"#, APIError.unknownSensor("s-9")),
        (409, #"{"error":"idempotency_conflict"}"#, APIError.rejected(statusCode: 409)),
        (403, #"{"error":"unknown_token"}"#, APIError.notAuthorized),
        (401, #"{"error":"missing_token"}"#, APIError.notAuthorized),
    ])
    func mapsHTTPErrors(status: Int, body: String, expected: APIError) async {
        StubURLProtocol.respond { _ in (status, Data(body.utf8)) }

        await #expect(throws: expected) {
            try await makeAPI().fetchReadings(sensorId: "s-9", since: nil)
        }
    }

    @Test func offlineFailsWithoutSendingARequest() async {
        StubURLProtocol.respond { _ in (200, Data("[]".utf8)) }
        var configuration = SimulationConfiguration.instant
        configuration.isOffline = true

        await #expect(throws: APIError.offline) {
            try await makeAPI(configuration).fetchSensors()
        }
        #expect(StubURLProtocol.requests.isEmpty)
    }

    @Test func debugEndpointsAreNotSimulated() async throws {
        StubURLProtocol.respond { _ in
            (200, Data(#"{"requestCount":3,"careLogRequestCount":1,"idempotentReplayCount":0,"storedCareLogCount":1}"#.utf8))
        }
        var configuration = SimulationConfiguration.instant
        configuration.isOffline = true

        let stats = try await makeAPI(configuration).serverStats()

        #expect(stats.storedCareLogCount == 1)
        #expect(StubURLProtocol.requests.first?.value(forHTTPHeaderField: "X-Simulate-Failure-Rate") == nil)
    }
}
