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
                    } else if usesDesktopLayout(for: proxy.size) {
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
        .frame(minWidth: 760, minHeight: 560)
        #endif
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
            #if os(iOS)
            .presentationDetents([.medium, .large])
            #else
            .frame(minWidth: 520, idealWidth: 560, minHeight: 520, idealHeight: 640)
            #endif
        }
        .task {
            dashboard.startAutoRefresh()
            #if os(iOS)
            BackgroundRefreshScheduler.schedule(refreshIntervalSeconds: settings.refreshInterval.seconds)
            #endif
        }
        .onDisappear {
            dashboard.stopAutoRefresh()
        }
        .onChange(of: settings.refreshInterval) { _, _ in
            dashboard.restartAutoRefresh()
            #if os(iOS)
            BackgroundRefreshScheduler.schedule(refreshIntervalSeconds: settings.refreshInterval.seconds)
            #endif
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

            Button {
                showingSettings = true
            } label: {
                Label(settings.language.text(.settings), systemImage: "gearshape")
            }
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

    private func usesDesktopLayout(for size: CGSize) -> Bool {
        #if os(macOS)
        size.width >= 980 && size.height >= 560
        #else
        size.width >= 900
        #endif
    }
}
