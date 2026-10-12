import Foundation

/// Loads the sensor catalogue that seeds the mock server.
enum SensorFixtures {
    static func load(from bundle: Bundle = .main) throws -> [Sensor] {
        guard let url = bundle.url(forResource: "sensors", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode([Sensor].self, from: Data(contentsOf: url))
    }
}
