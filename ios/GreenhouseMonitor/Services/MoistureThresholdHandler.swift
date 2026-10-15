//
//  ReadMoistureThreshold.swift
//  GreenhouseMonitor
//
//  Created by He Jianghao on 2026/10/15.
//

import Foundation


struct MoistureThresholdHandler {
	private let userDefaults: UserDefaults
	private let storageKey = "moistureThreshold_"

	init(userDefaults: UserDefaults = .standard) {
		self.userDefaults = userDefaults
	}
	
	
	private func storageKey(for sensorId: String) -> String {
		return storageKey + sensorId
	}

	func load(sensorId: String) -> MoistureThreshold? {
		guard let savedString = userDefaults.string(forKey: storageKey(for: sensorId)),
			  let data = savedString.data(using: .utf8) else {
			return nil
		}
		do {
			let threshold = try JSONDecoder().decode(
				MoistureThreshold.self,
				from: data
			)
			return threshold
		} catch {
			print("Failed to decode moisture threshold: \(error)")
			return nil
		}
	}

	func save(_ threshold: MoistureThreshold) {
		guard threshold.isValid,
			  let data = try? JSONEncoder().encode(threshold),
			  let savedString = String(data: data, encoding: .utf8) else {
			return
		}

		userDefaults.set(savedString, forKey: storageKey(for: threshold.sensorId))
	}

	func clear(_ threshold: MoistureThreshold) {
		userDefaults.removeObject(forKey: storageKey(for: threshold.sensorId))
	}
}
