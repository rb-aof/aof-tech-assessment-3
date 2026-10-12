import Foundation
import Observation

@MainActor
@Observable
final class SensorListViewModel {
    struct Row: Identifiable, Equatable {
        let sensor: Sensor
        let latest: Reading?

        var id: String { sensor.id }
    }

    struct Section: Identifiable, Equatable {
        let zone: String
        let rows: [Row]

        var id: String { zone }
    }

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let store: ReadingStore
    private let syncService: SyncService

    init(store: ReadingStore, syncService: SyncService) {
        self.store = store
        self.syncService = syncService
    }

    /// Sensors grouped by zone, both sorted alphabetically.
    var sections: [Section] {
        Dictionary(grouping: store.sensors, by: \.zone)
            .sorted { $0.key < $1.key }
            .map { zone, sensors in
                Section(
                    zone: zone,
                    rows: sensors
                        .sorted { $0.name < $1.name }
                        .map { Row(sensor: $0, latest: store.latestReading(for: $0.id)) }
                )
            }
    }

    var isEmpty: Bool {
        store.sensors.isEmpty
    }

    func onAppear() async {
        await sync(showingLoadingIndicator: isEmpty)
    }

    func refresh() async {
        await sync(showingLoadingIndicator: false)
    }

    private func sync(showingLoadingIndicator: Bool) async {
        if showingLoadingIndicator { isLoading = true }
        defer { isLoading = false }

        do {
            try await syncService.syncAll()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
