import SwiftUI

/// Developer-only controls for the mock server. Not part of the product UI.
struct DebugMenuView: View {
    @State var viewModel: DebugMenuViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Backend") {
                    LabeledContent("Server", value: viewModel.backendDescription)
                }

                Section("Network") {
                    Toggle("Offline", isOn: $viewModel.isOffline)
                    LabeledContent("Latency") {
                        Text(viewModel.latencySeconds, format: .number.precision(.fractionLength(1)))
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.latencySeconds, in: 0...3, step: 0.1)
                    Picker("Failure rate", selection: $viewModel.failureRate) {
                        Text(verbatim: "0%").tag(0.0)
                        Text(verbatim: "10%").tag(0.1)
                        Text(verbatim: "30%").tag(0.3)
                        Text(verbatim: "50%").tag(0.5)
                    }
                }

                Section("Server stats") {
                    LabeledContent("Requests", value: viewModel.stats.requestCount, format: .number)
                    LabeledContent("Care log requests", value: viewModel.stats.careLogRequestCount, format: .number)
                    LabeledContent("Idempotent replays", value: viewModel.stats.idempotentReplayCount, format: .number)
                    LabeledContent("Stored care logs", value: viewModel.stats.storedCareLogCount, format: .number)
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage)
                    }
                    Button("Refresh stats") {
                        Task { await viewModel.refreshStats() }
                    }
                }

                Section {
                    Button("Clear cached readings", role: .destructive) {
                        viewModel.clearCachedReadings()
                    }
                    Button("Reset server data", role: .destructive) {
                        Task { await viewModel.resetServer() }
                    }
                }
            }
            .navigationTitle("Debug menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await viewModel.load()
            }
            .onChange(of: viewModel.isOffline) { Task { await viewModel.apply() } }
            .onChange(of: viewModel.latencySeconds) { Task { await viewModel.apply() } }
            .onChange(of: viewModel.failureRate) { Task { await viewModel.apply() } }
        }
    }
}
