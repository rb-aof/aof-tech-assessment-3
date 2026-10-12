import SwiftUI

@main
struct GreenhouseMonitorApp: App {
    @State private var environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            SensorListView(environment: environment)
        }
    }
}
