import SwiftUI

@main
struct DeepSeekUsageMonitorApp: App {
    @State private var settingsStore: SettingsStore
    @State private var dashboardStore: DashboardStore

    init() {
        let settings = SettingsStore()
        let secrets = KeychainSecretStore()
        _settingsStore = State(initialValue: settings)
        _dashboardStore = State(initialValue: DashboardStore(settings: settings, secretStore: secrets))
    }

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            ContentView()
                .environment(settingsStore)
                .environment(dashboardStore)
                .preferredColorScheme(settingsStore.preferredColorScheme)
        }
        .defaultSize(width: 1120, height: 760)

        Settings {
            SettingsView()
                .environment(settingsStore)
                .environment(dashboardStore)
                .preferredColorScheme(settingsStore.preferredColorScheme)
        }
        #else
        WindowGroup {
            ContentView()
                .environment(settingsStore)
                .environment(dashboardStore)
                .preferredColorScheme(settingsStore.preferredColorScheme)
        }
        #endif
    }
}
