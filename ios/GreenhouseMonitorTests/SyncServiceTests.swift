import Foundation
import Testing
@testable import GreenhouseMonitor

@MainActor
struct SyncServiceTests {
    @Test func firstSyncFetchesSensorsAndReadings() async throws {
        let store = ReadingStore(fileURL: nil)
        let service = SyncService(api: TestData.makeAPI(), store: store)

        try await service.syncAll()

        #expect(store.sensors == TestData.sensors)
        for sensor in TestData.sensors {
            #expect(store.readings(for: sensor.id).count == TestData.readingsPerSensor)
        }
    }

    @Test func syncErrorsArePropagated() async {
        var configuration = MockGreenhouseAPI.Configuration.instant
        configuration.isOffline = true
        let service = SyncService(api: TestData.makeAPI(configuration: configuration), store: ReadingStore(fileURL: nil))

        await #expect(throws: APIError.offline) {
            try await service.syncAll()
        }
        #expect(service.isSyncing == false)
    }
}
