import Foundation

/// A single measurement reported by a sensor.
struct Reading: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let sensorId: String
    let timestamp: Date
    /// Volumetric soil moisture, 0–100 %.
    let soilMoisture: Double
    /// Air temperature in °C.
    let temperature: Double
    /// Relative air humidity, 0–100 %.
    let humidity: Double
}
