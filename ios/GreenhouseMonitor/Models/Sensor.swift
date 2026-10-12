import Foundation

/// A soil/air sensor installed somewhere in the greenhouse.
struct Sensor: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let zone: String
    let plant: String
}
