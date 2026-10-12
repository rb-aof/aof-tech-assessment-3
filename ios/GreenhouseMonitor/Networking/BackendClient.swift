import Foundation

/// Knobs for simulating a poor network, edited from the debug menu.
struct SimulationConfiguration: Codable, Equatable, Sendable {
    var latency: Duration = .milliseconds(500)
    /// Probability (0...1) that any request fails.
    var failureRate: Double = 0
    var isOffline = false

    static let instant = SimulationConfiguration(latency: .zero)
}

extension Duration {
    var milliseconds: Int {
        Int(((Double(components.seconds) + Double(components.attoseconds) / 1e18) * 1000).rounded())
    }
}

/// What the backend has seen from this client. Handy when checking upload behaviour.
struct ServerStats: Codable, Equatable, Sendable {
    var requestCount = 0
    var careLogRequestCount = 0
    /// Care log posts whose id had already been stored.
    var idempotentReplayCount = 0
    var storedCareLogCount = 0
}

/// Debug-only controls shared by the live and mock backends.
protocol SimulationControlling: Sendable {
    var configuration: SimulationConfiguration { get async }
    func updateConfiguration(_ configuration: SimulationConfiguration) async
    func serverStats() async throws -> ServerStats
    /// Deletes everything the server stored for this client (care logs and stats).
    func resetServer() async throws
}

/// Everything the app needs from a backend.
typealias BackendClient = GreenhouseAPI & ConnectivityMonitoring & SimulationControlling

/// Fans out online/offline changes to any number of `AsyncStream` subscribers.
struct OnlineStatusBroadcaster: Sendable {
    private let continuations = Locked<[UUID: AsyncStream<Bool>.Continuation]>([:])

    func stream(initialValue: Bool) -> AsyncStream<Bool> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        continuation.yield(initialValue)
        continuation.onTermination = { [continuations] _ in
            continuations.withLock { $0[id] = nil }
        }
        continuations.withLock { $0[id] = continuation }
        return stream
    }

    func broadcast(_ isOnline: Bool) {
        for continuation in continuations.withLock({ Array($0.values) }) {
            continuation.yield(isOnline)
        }
    }
}

/// Minimal lock-protected box (iOS 17 has no `Mutex`).
final class Locked<Value>: @unchecked Sendable {
    private var value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        self.value = value
    }

    func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}
