import Testing
@testable import GreenhouseMonitor

struct SensorFixturesTests {
    @Test func bundledFixturesDecode() throws {
        let sensors = try SensorFixtures.load()

        #expect(!sensors.isEmpty)
        #expect(Set(sensors.map(\.id)).count == sensors.count, "Sensor ids must be unique")
    }
}
