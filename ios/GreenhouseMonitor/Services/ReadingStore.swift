import Foundation
import Observation
import os

/// Local cache of sensors and their readings, persisted as JSON so the app has data offline.
@MainActor
@Observable
final class ReadingStore {
    private(set) var sensors: [Sensor] = []
    /// Readings per sensor id, oldest first.
    private(set) var readingsBySensor: [String: [Reading]] = [:]

    @ObservationIgnored private let fileURL: URL?
    @ObservationIgnored private let logger = Logger(subsystem: "com.example.GreenhouseMonitor", category: "ReadingStore")

    /// - Parameter fileURL: Where to persist the cache. Pass `nil` for an in-memory store.
    init(fileURL: URL?) {
        self.fileURL = fileURL
        loadFromDisk()
    }

    static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(path: "readings-cache.json")
    }

    // MARK: - Queries

    /// Newest first.
    func readings(for sensorId: String) -> [Reading] {
        readingsBySensor[sensorId, default: []].reversed()
    }

    func latestReading(for sensorId: String) -> Reading? {
        readingsBySensor[sensorId]?.last
    }

    // MARK: - Mutations

    func replaceSensors(_ sensors: [Sensor]) {
        self.sensors = sensors
        persist()
    }

    func append(_ newReadings: [Reading], for sensorId: String) {
        guard !newReadings.isEmpty else { return }
        var readings = readingsBySensor[sensorId, default: []]
        readings.append(contentsOf: newReadings)
        readings.sort { $0.timestamp < $1.timestamp }
        readingsBySensor[sensorId] = readings
        persist()
    }

    func removeAllReadings() {
        readingsBySensor = [:]
        persist()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var sensors: [Sensor]
        var readingsBySensor: [String: [Reading]]
    }

    private func loadFromDisk() {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path()) else { return }
        do {
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: fileURL))
            sensors = snapshot.sensors
            readingsBySensor = snapshot.readingsBySensor
        } catch {
            logger.error("Failed to load cache: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func persist() {
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(Snapshot(sensors: sensors, readingsBySensor: readingsBySensor))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Failed to save cache: \(error.localizedDescription, privacy: .public)")
        }
    }
}
