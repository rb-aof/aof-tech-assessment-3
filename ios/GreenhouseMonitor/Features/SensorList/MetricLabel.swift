import SwiftUI

/// Icon + formatted measurement, shared by the list and detail screens.
struct MetricLabel: View {
    enum Format {
        case percentValue
        case celsius

        func string(for value: Double) -> String {
            switch self {
            case .percentValue:
                (value / 100).formatted(.percent.precision(.fractionLength(0)))
            case .celsius:
                Measurement(value: value, unit: UnitTemperature.celsius)
                    .formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(1))))
            }
        }
    }

    let systemImage: String
    let value: Double
    let format: Format

    var body: some View {
        Label(format.string(for: value), systemImage: systemImage)
            .monospacedDigit()
    }
}
