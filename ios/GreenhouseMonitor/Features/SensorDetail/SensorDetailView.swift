import SwiftUI
import Foundation

struct SensorDetailView: View {
    @State var viewModel: SensorDetailViewModel
	@State private var showingThresholdView = false
	
	
	init(viewModel: SensorDetailViewModel, showingThresholdView: Bool = false) {
		self.viewModel = viewModel
		
		self.showingThresholdView = showingThresholdView
	}
	
	private func rangeColumn(
		value: Double,
		label: String
	) -> some View {
		VStack(spacing: 4) {
			Text(value / 100, format: .percent).font(.title3)
				.fontWeight(.medium)
			
			Text(label)
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity)
	}

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
            }
			
			Section {
				if !viewModel.moistureThreshold.isEmpty {
					HStack {
						rangeColumn(value: viewModel.moistureThreshold.minMoisture, label: "Min")
						Text("−")
							.foregroundStyle(.secondary)
						rangeColumn(value: viewModel.moistureThreshold.maxMoisture, label: "Max")
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 8)
				}
			} header: {
				HStack {
					Text("Moisture range")
					Spacer()
					Button("Edit") {
						showingThresholdView = true
					}
					.tint(.green)
				}
			}


            Section("Latest") {
                if let latest = viewModel.latest {
                    LabeledContent("Soil moisture") {
                        MetricLabel(systemImage: "drop", value: latest.soilMoisture, format: .percentValue)
                    }
                    LabeledContent("Temperature") {
                        MetricLabel(systemImage: "thermometer.medium", value: latest.temperature, format: .celsius)
                    }
                    LabeledContent("Humidity") {
                        MetricLabel(systemImage: "humidity", value: latest.humidity, format: .percentValue)
                    }
                    LabeledContent("Updated") {
                        Text(latest.timestamp, style: .relative)
                    }
                } else {
                    Text("No readings yet")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                ForEach(viewModel.readings) { reading in
                    ReadingRow(reading: reading)
                }
            } header: {
                Text("History (\(viewModel.readings.count))")
            }
        }
		.sheet(isPresented: $showingThresholdView, onDismiss: {
			viewModel.refreshMoistureThreshold()
		}) {
			MoistureThresholdView(
				viewModel: MoistureThresholdViewModel(viewModel.moistureThreshold)
			)
		}
        .navigationTitle(viewModel.sensor.name)
        .refreshable {
            await viewModel.refresh()
        }
    }
}

private struct ReadingRow: View {
    let reading: Reading

    var body: some View {
        HStack {
            Text(reading.timestamp, format: .dateTime.hour().minute())
                .monospacedDigit()
            Spacer()
            MetricLabel(systemImage: "drop", value: reading.soilMoisture, format: .percentValue)
            MetricLabel(systemImage: "thermometer.medium", value: reading.temperature, format: .celsius)
        }
        .font(.callout)
    }
}

#Preview {
	makeSensorDetailPreview()
}

@MainActor
private func makeSensorDetailPreview() -> some View {
	//{ "id": "gh-a-01", "name": "Bench A1", "zone": "Propagation", "plant": "Basil seedlings" },
	let sensor = Sensor(id: "gh-a-01", name: "Bench A1", zone: "Propagation", plant: "Basil seedlings")
	
	let store = ReadingStore(fileURL: ReadingStore.defaultFileURL)
	
	let api = MockGreenhouseAPI(sensors: store.sensors)
	
	let syncService = SyncService(api: api, store: store)

	let viewModel = SensorDetailViewModel(sensor: sensor, store: store, syncService: syncService)

	return SensorDetailView(viewModel: viewModel)
}
