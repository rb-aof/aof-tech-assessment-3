import Foundation
@testable import GreenhouseMonitor

enum TestData {
    /// A fixed "now" so generated readings are stable across runs.
    static let now = Date(timeIntervalSince1970: 1_750_000_000)

    static let sensors = [
        Sensor(id: "s-1", name: "Bench 1", zone: "North", plant: "Basil"),
        Sensor(id: "s-2", name: "Bench 2", zone: "North", plant: "Mint"),
        Sensor(id: "s-3", name: "Pot 1", zone: "South", plant: "Aloe"),
    ]

    /// Number of readings the mock server keeps per sensor.
    static let readingsPerSensor = Int(MockGreenhouseAPI.retentionWindow / MockGreenhouseAPI.readingInterval)

    static func makeAPI(
        configuration: MockGreenhouseAPI.Configuration = .instant,
        now: Date = TestData.now
    ) -> MockGreenhouseAPI {
        MockGreenhouseAPI(sensors: sensors, configuration: configuration, seed: 7, now: { now })
    }

    static func reading(id: String, sensorId: String = "s-1", minutesAgo: Double, moisture: Double = 50) -> Reading {
        Reading(
            id: id,
            sensorId: sensorId,
            timestamp: now.addingTimeInterval(-minutesAgo * 60),
            soilMoisture: moisture,
            temperature: 21,
            humidity: 60
        )
    }

    static func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "GreenhouseMonitorTests-\(UUID().uuidString)")
            .appending(path: "cache.json")
    }
}
