import Foundation

/// Pulls sensors and new readings from the backend into the local `ReadingStore`.
@MainActor
final class SyncService {
    private let api: any GreenhouseAPI
    private let store: ReadingStore

    private(set) var isSyncing = false

    init(api: any GreenhouseAPI, store: ReadingStore) {
        self.api = api
        self.store = store
    }

    /// Refreshes the sensor list, then fetches any readings newer than the ones already cached.
    func syncAll() async throws {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let sensors = try await api.fetchSensors()
        store.replaceSensors(sensors)

        for sensor in sensors {
            let since = store.readings(for: sensor.id).last?.timestamp
            let readings = try await api.fetchReadings(sensorId: sensor.id, since: since)
            store.append(readings, for: sensor.id)
        }
    }
}
