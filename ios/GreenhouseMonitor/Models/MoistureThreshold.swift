//
//  MoistureThreshold.swift
//  GreenhouseMonitor
//
//  Created by He Jianghao on 2026/10/15.
//

import Foundation


struct MoistureThreshold: Codable, Sendable {
	let sensorId: String
	
	var minMoisture: Double = 0
	
	var maxMoisture: Double = 0
	
	var isValid:  Bool {
		return minMoisture >= 0 && maxMoisture <= 100 && minMoisture <= maxMoisture
	}
	
	var isEmpty: Bool {
		return minMoisture == 0 && maxMoisture == 0
	}
}
