import SwiftUI

struct SensorListView: View {
    private let environment: AppEnvironment
    @State private var viewModel: SensorListViewModel
    @State private var isShowingDebugMenu = false

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = State(initialValue: SensorListViewModel(
            store: environment.store,
            syncService: environment.syncService
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                if let backendWarning = environment.backendWarning {
                    BackendWarningBanner(message: backendWarning)
                }

                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                ForEach(viewModel.sections) { section in
                    Section(section.zone) {
                        ForEach(section.rows) { row in
                            NavigationLink(value: row.sensor) {
                                SensorRow(row: row)
                            }
                        }
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading sensors…")
                } else if viewModel.isEmpty && viewModel.errorMessage == nil {
                    ContentUnavailableView("No sensors", systemImage: "leaf")
                }
            }
            .navigationTitle("Greenhouse")
            .navigationDestination(for: Sensor.self) { sensor in
                SensorDetailView(viewModel: SensorDetailViewModel(
                    sensor: sensor,
                    store: environment.store,
                    syncService: environment.syncService
                ))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingDebugMenu = true
                    } label: {
                        Label("Debug menu", systemImage: "ladybug")
                    }
                }
            }
            .sheet(isPresented: $isShowingDebugMenu) {
                DebugMenuView(viewModel: DebugMenuViewModel(
                    api: environment.api,
                    backendDescription: environment.backendDescription,
                    store: environment.store,
                    settings: environment.debugSettings
                ))
            }
            .task {
                await viewModel.onAppear()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

private struct SensorRow: View {
    let row: SensorListViewModel.Row

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(row.sensor.name)
                .font(.headline)
            Text(row.sensor.plant)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let latest = row.latest {
                HStack(spacing: 12) {
                    MetricLabel(systemImage: "drop", value: latest.soilMoisture, format: .percentValue)
                    MetricLabel(systemImage: "thermometer.medium", value: latest.temperature, format: .celsius)
                }
                .font(.caption)
            } else {
                Text("No readings yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Shown while `Backend.plist` is incomplete, so a missing email can't go unnoticed.
private struct BackendWarningBanner: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Using offline mock data", systemImage: "person.crop.circle.badge.exclamationmark")
                .font(.headline)
            Text(message)
                .font(.footnote)
        }
        .foregroundStyle(.red)
        .accessibilityElement(children: .combine)
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .foregroundStyle(.orange)
            .font(.footnote)
    }
}
