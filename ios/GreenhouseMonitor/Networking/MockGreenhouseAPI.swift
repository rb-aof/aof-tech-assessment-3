import Foundation

/// In-process fake of the greenhouse backend, used by tests and whenever `Backend.plist` is not filled in.
///
/// - Readings are generated deterministically from the sensor id and the time slot, one every
///   `readingInterval`, and kept for `retentionWindow`.
/// - `Configuration` controls latency, random failures and an offline switch. The debug menu in
///   the app edits it at runtime.
/// - `stats` exposes what the "server" has seen, which is handy when checking upload behaviour.
actor MockGreenhouseAPI: BackendClient {
    typealias Configuration = SimulationConfiguration
    typealias Stats = ServerStats

    static let readingInterval: TimeInterval = 60
    static let retentionWindow: TimeInterval = 2 * 60 * 60

    private(set) var configuration: Configuration
    private(set) var stats = Stats()

    private let sensors: [Sensor]
    private let now: @Sendable () -> Date
    private var random: SeededRandomNumberGenerator
    private var storedCareLogs: [String: (upload: CareLogUpload, receipt: CareLogReceipt)] = [:]
    private var nextServerId = 1
    private let onlineStatus = OnlineStatusBroadcaster()

    init(
        sensors: [Sensor],
        configuration: Configuration = Configuration(),
        seed: UInt64 = 42,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.sensors = sensors
        self.configuration = configuration
        self.random = SeededRandomNumberGenerator(seed: seed)
        self.now = now
    }

    // MARK: - Configuration

    func updateConfiguration(_ newValue: Configuration) {
        let connectivityChanged = newValue.isOffline != configuration.isOffline
        configuration = newValue
        if connectivityChanged {
            onlineStatus.broadcast(!newValue.isOffline)
        }
    }

    func serverStats() -> ServerStats {
        stats
    }

    func resetServer() {
        stats = ServerStats()
        storedCareLogs = [:]
        nextServerId = 1
    }

    /// Care logs the server has stored for a sensor, in the order they were received.
    func storedCareLogs(for sensorId: String) -> [CareLogUpload] {
        storedCareLogs.values
            .filter { $0.upload.sensorId == sensorId }
            .sorted { $0.receipt.serverId < $1.receipt.serverId }
            .map(\.upload)
    }

    // MARK: - ConnectivityMonitoring

    var isOnline: Bool {
        !configuration.isOffline
    }

    func onlineUpdates() -> AsyncStream<Bool> {
        onlineStatus.stream(initialValue: !configuration.isOffline)
    }

    // MARK: - GreenhouseAPI

    func fetchSensors() async throws -> [Sensor] {
        try await simulateRequest()
        try simulateRandomFailure()
        return sensors
    }

    func fetchReadings(sensorId: String, since: Date?) async throws -> [Reading] {
        try await simulateRequest()
        try simulateRandomFailure()
        guard sensors.contains(where: { $0.id == sensorId }) else {
            throw APIError.unknownSensor(sensorId)
        }

        let lastSlot = Int((now().timeIntervalSince1970 / Self.readingInterval).rounded(.down))
        let slotCount = Int(Self.retentionWindow / Self.readingInterval)
        let firstSlot = lastSlot - slotCount + 1

        return (firstSlot...lastSlot)
            .map { Self.reading(sensorId: sensorId, slot: $0) }
            .filter { reading in since.map { reading.timestamp > $0 } ?? true }
    }

    func postCareLog(_ entry: CareLogUpload) async throws -> CareLogReceipt {
        stats.careLogRequestCount += 1
        try await simulateRequest()

        // Some failures happen before the server stores anything, others after it has
        // already stored the entry but before the client receives the response.
        let failsAfterProcessing = shouldFail()
        if !failsAfterProcessing {
            try simulateRandomFailure()
        }

        let receipt: CareLogReceipt
        if let existing = storedCareLogs[entry.id] {
            stats.idempotentReplayCount += 1
            receipt = existing.receipt
        } else {
            receipt = CareLogReceipt(id: entry.id, serverId: nextServerId, receivedAt: now())
            nextServerId += 1
            storedCareLogs[entry.id] = (entry, receipt)
            stats.storedCareLogCount = storedCareLogs.count
        }

        if failsAfterProcessing {
            throw APIError.timeout
        }
        return receipt
    }

    // MARK: - Simulation

    private func simulateRequest() async throws {
        stats.requestCount += 1
        guard !configuration.isOffline else { throw APIError.offline }
        if configuration.latency > .zero {
            try await Task.sleep(for: configuration.latency)
        }
        // Connectivity may have dropped while the request was in flight.
        guard !configuration.isOffline else { throw APIError.offline }
    }

    private func simulateRandomFailure() throws {
        if shouldFail() {
            throw APIError.serverError(statusCode: 503)
        }
    }

    private func shouldFail() -> Bool {
        guard configuration.failureRate > 0 else { return false }
        return Double.random(in: 0..<1, using: &random) < configuration.failureRate
    }

    private static func reading(sensorId: String, slot: Int) -> Reading {
        let sensorHash = stableHash(sensorId)
        var generator = SeededRandomNumberGenerator(seed: sensorHash ^ UInt64(bitPattern: Int64(slot)))

        // Each sensor gets its own baseline so some beds run dry and others stay wet.
        let baseline = 20 + Double(sensorHash % 55)
        let phase = Double(slot) / 15
        let moisture = baseline + 6 * sin(phase) + Double.random(in: -1.5...1.5, using: &generator)
        let temperature = 21 + 3 * sin(phase / 4) + Double.random(in: -0.4...0.4, using: &generator)
        let humidity = 60 + 10 * cos(phase / 3) + Double.random(in: -2...2, using: &generator)

        return Reading(
            id: "\(sensorId)-\(slot)",
            sensorId: sensorId,
            timestamp: Date(timeIntervalSince1970: Double(slot) * readingInterval),
            soilMoisture: min(max(moisture, 0), 100),
            temperature: temperature,
            humidity: min(max(humidity, 0), 100)
        )
    }

    /// FNV-1a: stable across launches, unlike `Hasher`.
    private static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x0100_0000_01B3
        }
        return hash
    }
}
