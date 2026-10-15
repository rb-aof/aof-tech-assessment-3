//
//  MoistureSettingViewModel.swift
//  GreenhouseMonitor
//
//  Created by He Jianghao on 2026/10/15.
//

import Foundation

@MainActor
@Observable
final class MoistureThresholdViewModel {
	
	var moistureThreshold: MoistureThreshold
	

	init(_ moistureThreshold: MoistureThreshold) {
		self.moistureThreshold = moistureThreshold
	}
	
	
	func save() {
		MoistureThresholdHandler().save(moistureThreshold)
	}
	
	func clear() {
		moistureThreshold.minMoisture = 0
		moistureThreshold.maxMoisture = 0
	}

}
