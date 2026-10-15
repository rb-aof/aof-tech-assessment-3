import Foundation
import Observation

@MainActor
@Observable
final class SensorDetailViewModel {
    let sensor: Sensor
    private(set) var errorMessage: String?

    private let store: ReadingStore
    private let syncService: SyncService
	
	private(set) var moistureThreshold: MoistureThreshold

    init(sensor: Sensor, store: ReadingStore, syncService: SyncService) {
        self.sensor = sensor
        self.store = store
        self.syncService = syncService
		
		self.moistureThreshold = MoistureThresholdHandler().load(sensorId: sensor.id) ?? MoistureThreshold(sensorId: sensor.id)
		
		checkMoistureThreshold()
    }

    /// Newest first.
    var readings: [Reading] {
        store.readings(for: sensor.id)
    }

    var latest: Reading? {
        store.latestReading(for: sensor.id)
    }
	
	func refreshMoistureThreshold() {
		self.moistureThreshold = MoistureThresholdHandler().load(sensorId: sensor.id) ?? MoistureThreshold(sensorId: sensor.id)
		
		checkMoistureThreshold()
	}
	
	func checkMoistureThreshold() {
		if moistureThreshold.isEmpty {
			errorMessage = nil
			return
		}
		
		if let theMoisture = latest?.soilMoisture {
			if theMoisture < moistureThreshold.minMoisture {
				errorMessage = String(
					localized: "moisture.belowMinimum",
					defaultValue: "\(sensor.name), soil moisture \(theMoisture)%, below minimum of \(moistureThreshold.minMoisture)%"
				)
			} else if theMoisture > moistureThreshold.maxMoisture {
				errorMessage = String(
					localized: "moisture.aboveMaximum",
					defaultValue: "\(sensor.name), soil moisture \(theMoisture)%, above maximum of \(moistureThreshold.maxMoisture)%"
				)
			} else {
				errorMessage = nil
			}
		}
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
