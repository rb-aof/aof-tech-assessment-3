import Foundation
import Testing
@testable import GreenhouseMonitor

@MainActor
struct SensorListViewModelTests {
    @Test func sectionsAreGroupedByZoneWithLatestReading() async {
        let store = ReadingStore(fileURL: nil)
        let viewModel = SensorListViewModel(store: store, syncService: SyncService(api: TestData.makeAPI(), store: store))

        await viewModel.onAppear()

        #expect(viewModel.sections.map(\.zone) == ["North", "South"])
        #expect(viewModel.sections[0].rows.map(\.sensor.name) == ["Bench 1", "Bench 2"])
        #expect(viewModel.sections.flatMap(\.rows).allSatisfy { $0.latest != nil })
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test func failedSyncShowsErrorMessage() async {
        var configuration = MockGreenhouseAPI.Configuration.instant
        configuration.isOffline = true
        let store = ReadingStore(fileURL: nil)
        let viewModel = SensorListViewModel(
            store: store,
            syncService: SyncService(api: TestData.makeAPI(configuration: configuration), store: store)
        )

        await viewModel.refresh()

        #expect(viewModel.errorMessage == APIError.offline.localizedDescription)
    }
}
