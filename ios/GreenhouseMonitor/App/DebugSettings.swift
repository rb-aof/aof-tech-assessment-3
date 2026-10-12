import Foundation

/// Persists the mock server configuration chosen in the debug menu across launches.
@MainActor
final class DebugSettings {
    private let defaults: UserDefaults
    private let key = "debug.mockServerConfiguration"

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func load() -> SimulationConfiguration {
        guard
            let data = defaults.data(forKey: key),
            let configuration = try? JSONDecoder().decode(SimulationConfiguration.self, from: data)
        else {
            return SimulationConfiguration()
        }
        return configuration
    }

    func save(_ configuration: SimulationConfiguration) {
        defaults.set(try? JSONEncoder().encode(configuration), forKey: key)
    }
}
