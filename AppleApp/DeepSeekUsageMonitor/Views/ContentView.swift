import SwiftUI

struct ContentView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(DashboardStore.self) private var dashboard
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var showingSettings = false
    @State private var isFocusMode = false

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()
                GeometryReader { proxy in
                    if isFocusMode {
                        FocusDashboardView()
                    } else if proxy.size.width >= 900 {
                        DesktopDashboardView()
                    } else {
                        MobileDashboardView()
                    }
                }
            }
            .navigationTitle("DeepSeek")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { dashboardToolbar }
        }
        #if os(macOS)
        .frame(minWidth: 960, minHeight: 640)
        #endif
        #if os(iOS)
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
            .presentationDetents([.medium, .large])
        }
        #endif
        .task {
            dashboard.startAutoRefresh()
        }
        .onDisappear {
            dashboard.stopAutoRefresh()
        }
        .onChange(of: settings.refreshInterval) { _, _ in
            dashboard.restartAutoRefresh()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            dashboard.tickUptime()
        }
    }

    @ToolbarContentBuilder
    private var dashboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                Task { await dashboard.refresh() }
            } label: {
                Label(settings.language.text(.refresh), systemImage: dashboard.isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
            }
            .disabled(dashboard.isLoading)

            Button {
                toggleLanguage()
            } label: {
                Text(settings.language == .zh ? "CN" : "EN")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
            }
            .help(settings.language.text(.language))

            Button {
                cycleTheme()
            } label: {
                Label(settings.language.text(.theme), systemImage: themeIcon)
            }

            Button {
                isFocusMode.toggle()
            } label: {
                Label(settings.language.text(.focusMode), systemImage: isFocusMode ? "viewfinder.circle.fill" : "viewfinder")
            }
            .help(settings.language.text(.focusMode))

            #if os(iOS)
            Button {
                showingSettings = true
            } label: {
                Label(settings.language.text(.settings), systemImage: "gearshape")
            }
            #else
            SettingsLink {
                Label(settings.language.text(.settings), systemImage: "gearshape")
            }
            #endif
        }
    }

    private var themeIcon: String {
        switch settings.appTheme {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    private func toggleLanguage() {
        settings.language = settings.language == .zh ? .en : .zh
    }

    private func cycleTheme() {
        switch settings.appTheme {
        case .dark:
            settings.appTheme = .light
        case .light:
            settings.appTheme = .system
        case .system:
            settings.appTheme = .dark
        }
    }
}
