//
//  MoistureThresholdTests.swift
//  GreenhouseMonitor
//
//  Created by He Jianghao on 2026/10/15.
//

import Foundation
import Testing
@testable import GreenhouseMonitor

struct MoistureThresholdTests {

	// MARK: - isValid

	@Test
	func defaultThresholdIsValid() {
		let sensor = TestData.sensors[0]
		let threshold = MoistureThreshold(sensorId: sensor.id)

		#expect(threshold.isValid)
	}

	@Test
	func validRangeIsValid() {
		let sensor = TestData.sensors[0]
		var threshold = MoistureThreshold(sensorId: sensor.id)
		threshold.minMoisture = 25
		threshold.maxMoisture = 60

		#expect(threshold.isValid)
	}

	@Test
	func negativeMinimumIsInvalid() {
		let sensor = TestData.sensors[0]
		var threshold = MoistureThreshold(sensorId: sensor.id)
		threshold.minMoisture = -1
		threshold.maxMoisture = 60

		#expect(!threshold.isValid)
	}

	@Test
	func maximumAbove100IsInvalid() {
		let sensor = TestData.sensors[0]
		var threshold = MoistureThreshold(sensorId: sensor.id)
		threshold.minMoisture = 25
		threshold.maxMoisture = 101

		#expect(!threshold.isValid)
	}

	@Test
	func minimumGreaterThanMaximumIsInvalid() {
		let sensor = TestData.sensors[0]
		var threshold = MoistureThreshold(sensorId: sensor.id)
		threshold.minMoisture = 70
		threshold.maxMoisture = 60

		#expect(!threshold.isValid)
	}

	// MARK: - isEmpty

	@Test
	func defaultThresholdIsEmpty() {
		let sensor = TestData.sensors[0]
		let threshold = MoistureThreshold(sensorId: sensor.id)

		#expect(threshold.isEmpty)
	}

	@Test
	func thresholdWithMinimumIsNotEmpty() {
		let sensor = TestData.sensors[0]
		var threshold = MoistureThreshold(sensorId: sensor.id)
		threshold.minMoisture = 25

		#expect(!threshold.isEmpty)
	}

	@Test
	func thresholdWithMaximumIsNotEmpty() {
		let sensor = TestData.sensors[0]
		var threshold = MoistureThreshold(sensorId: sensor.id)
		threshold.maxMoisture = 60

		#expect(!threshold.isEmpty)
	}

	@Test
	func zeroValuesAreEmpty() {
		let sensor = TestData.sensors[0]
		var threshold = MoistureThreshold(sensorId: sensor.id)
		threshold.minMoisture = 0
		threshold.maxMoisture = 0

		#expect(threshold.isEmpty)
	}
}
