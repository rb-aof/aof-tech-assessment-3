import Foundation
import Testing
@testable import GreenhouseMonitor

struct MockGreenhouseAPITests {
    @Test func readingsCoverTheRetentionWindowOldestFirst() async throws {
        let api = TestData.makeAPI()

        let readings = try await api.fetchReadings(sensorId: "s-1", since: nil)

        #expect(readings.count == TestData.readingsPerSensor)
        #expect(readings.map(\.timestamp) == readings.map(\.timestamp).sorted())
        #expect(readings.allSatisfy { (0...100).contains($0.soilMoisture) })
    }

    @Test func readingsAreDeterministic() async throws {
        let first = try await TestData.makeAPI().fetchReadings(sensorId: "s-2", since: nil)
        let second = try await TestData.makeAPI().fetchReadings(sensorId: "s-2", since: nil)

        #expect(first == second)
    }

    @Test func sinceOnlyReturnsNewerReadings() async throws {
        let api = TestData.makeAPI()
        let all = try await api.fetchReadings(sensorId: "s-1", since: nil)
        let cutoff = all[all.count - 4].timestamp

        let newer = try await api.fetchReadings(sensorId: "s-1", since: cutoff)

        #expect(newer == Array(all.suffix(3)))
    }

    @Test func unknownSensorThrows() async {
        let api = TestData.makeAPI()

        await #expect(throws: APIError.unknownSensor("nope")) {
            try await api.fetchReadings(sensorId: "nope", since: nil)
        }
    }

    @Test func offlineRequestsFail() async {
        var configuration = MockGreenhouseAPI.Configuration.instant
        configuration.isOffline = true
        let api = TestData.makeAPI(configuration: configuration)

        await #expect(throws: APIError.offline) {
            try await api.fetchSensors()
        }
    }

    @Test func careLogPostIsIdempotent() async throws {
        let api = TestData.makeAPI()
        let entry = CareLogUpload(id: "log-1", sensorId: "s-1", kind: "watered", note: nil, createdAt: TestData.now)

        let first = try await api.postCareLog(entry)
        let second = try await api.postCareLog(entry)

        #expect(first == second)
        let stats = await api.stats
        #expect(stats.storedCareLogCount == 1)
        #expect(stats.idempotentReplayCount == 1)
        #expect(await api.storedCareLogs(for: "s-1") == [entry])
    }

    @Test func connectivityUpdatesFollowConfiguration() async {
        let api = TestData.makeAPI()
        var iterator = await api.onlineUpdates().makeAsyncIterator()

        let initial = await iterator.next()
        #expect(initial == true)

        var offline = MockGreenhouseAPI.Configuration.instant
        offline.isOffline = true
        await api.updateConfiguration(offline)

        let afterChange = await iterator.next()
        #expect(afterChange == false)
    }
}
