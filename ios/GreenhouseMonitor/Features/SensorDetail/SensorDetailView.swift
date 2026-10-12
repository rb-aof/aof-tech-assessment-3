import SwiftUI

struct SensorDetailView: View {
    @State var viewModel: SensorDetailViewModel

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
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
