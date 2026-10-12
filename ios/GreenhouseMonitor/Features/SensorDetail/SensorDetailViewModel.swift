import Foundation
import Observation

@MainActor
@Observable
final class SensorDetailViewModel {
    let sensor: Sensor
    private(set) var errorMessage: String?

    private let store: ReadingStore
    private let syncService: SyncService

    init(sensor: Sensor, store: ReadingStore, syncService: SyncService) {
        self.sensor = sensor
        self.store = store
        self.syncService = syncService
    }

    /// Newest first.
    var readings: [Reading] {
        store.readings(for: sensor.id)
    }

    var latest: Reading? {
        store.latestReading(for: sensor.id)
    }

    func refresh() async {
        do {
            try await syncService.syncAll()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
