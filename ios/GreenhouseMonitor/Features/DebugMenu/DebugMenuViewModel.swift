import Foundation
import Observation

@MainActor
@Observable
final class DebugMenuViewModel {
    var latencySeconds: Double = 0.5
    var failureRate: Double = 0
    var isOffline = false
    private(set) var stats = ServerStats()
    private(set) var errorMessage: String?
    let backendDescription: String

    private let api: any BackendClient
    private let store: ReadingStore
    private let settings: DebugSettings

    init(api: any BackendClient, backendDescription: String, store: ReadingStore, settings: DebugSettings) {
        self.api = api
        self.backendDescription = backendDescription
        self.store = store
        self.settings = settings
    }

    func load() async {
        let configuration = await api.configuration
        latencySeconds = Double(configuration.latency.milliseconds) / 1000
        failureRate = configuration.failureRate
        isOffline = configuration.isOffline
        await refreshStats()
    }

    func apply() async {
        let configuration = SimulationConfiguration(
            latency: .milliseconds(Int((latencySeconds * 1000).rounded())),
            failureRate: failureRate,
            isOffline: isOffline
        )
        await api.updateConfiguration(configuration)
        settings.save(configuration)
    }

    func refreshStats() async {
        do {
            stats = try await api.serverStats()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetServer() async {
        do {
            try await api.resetServer()
            await refreshStats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearCachedReadings() {
        store.removeAllReadings()
    }
}
