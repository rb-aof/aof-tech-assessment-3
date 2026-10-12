import Foundation
import os

/// Composition root: owns the long-lived services and hands them to the features.
@MainActor
final class AppEnvironment {
    let api: any BackendClient
    /// Human-readable description of the backend in use, shown in the debug menu.
    let backendDescription: String
    /// Set when the live backend is not configured; shown as a banner on the main screen.
    let backendWarning: String?
    let store: ReadingStore
    let syncService: SyncService
    let debugSettings: DebugSettings

    init(
        api: any BackendClient,
        backendDescription: String,
        backendWarning: String? = nil,
        store: ReadingStore,
        debugSettings: DebugSettings
    ) {
        self.api = api
        self.backendDescription = backendDescription
        self.backendWarning = backendWarning
        self.store = store
        self.debugSettings = debugSettings
        self.syncService = SyncService(api: api, store: store)
    }

    static func live() -> AppEnvironment {
        let debugSettings = DebugSettings(defaults: .standard)
        let configuration = debugSettings.load()
        let store = ReadingStore(fileURL: ReadingStore.defaultFileURL)

        switch BackendConfiguration.load() {
        case .configured(let backend):
            return AppEnvironment(
                api: LiveGreenhouseAPI(backend: backend, configuration: configuration),
                backendDescription: backend.baseURL.host() ?? backend.baseURL.absoluteString,
                store: store,
                debugSettings: debugSettings
            )

        case .notConfigured(let reason):
            Logger(subsystem: "com.example.GreenhouseMonitor", category: "Backend")
                .error("Live backend not configured, using the in-app mock. \(reason, privacy: .public)")
            let sensors = (try? SensorFixtures.load()) ?? []
            return AppEnvironment(
                api: MockGreenhouseAPI(sensors: sensors, configuration: configuration),
                backendDescription: String(localized: "In-app mock"),
                backendWarning: reason,
                store: store,
                debugSettings: debugSettings
            )
        }
    }
}
