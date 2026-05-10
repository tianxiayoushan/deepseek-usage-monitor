import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(DashboardStore.self) private var dashboard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemColorScheme

    @State private var apiKeyInput = ""
    @State private var creditInput = ""
    @State private var saveState: SaveState = .idle
    @State private var validationMessage: String?

    private enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case failed(String)
    }

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        @Bindable var settings = settings

        Group {
            #if os(macOS)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    MacSettingsSection(title: settings.language.text(.deepseekApiKey)) {
                        HStack {
                            Label(settings.language.text(.deepseekApiKey), systemImage: "key.fill")
                            Spacer()
                            Text(dashboard.apiKeyConfigured ? settings.language.text(.configuredLocally) : settings.language.text(.notConfigured))
                                .foregroundStyle(dashboard.apiKeyConfigured ? palette.accent : palette.muted)
                        }
                        SecureField(settings.language.text(.enterNewApiKey), text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Button(role: .destructive) {
                                clearKey()
                            } label: {
                                Label(settings.language.text(.clearKey), systemImage: "trash")
                            }
                            .disabled(!dashboard.apiKeyConfigured)
                            Spacer()
                        }
                    }

                    MacSettingsSection(title: settings.language.text(.initialTotalCredit)) {
                        TextField("80.00", text: $creditInput)
                            .textFieldStyle(.roundedBorder)
                        Stepper(value: $settings.gaugeMaxAmount, in: 100...1000, step: 100) {
                            HStack {
                                Text(settings.language.text(.gaugeRange))
                                Spacer()
                                Text("MAX \(Int(settings.gaugeMaxAmount)) CNY")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Picker(settings.language.text(.refreshInterval), selection: $settings.refreshInterval) {
                            ForEach(RefreshInterval.allCases) { interval in
                                Text("\(interval.seconds)s").tag(interval)
                            }
                        }
                        .pickerStyle(.menu)
                        Text(settings.language.text(.estimateNote))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    MacSettingsSection(title: settings.language.text(.settings)) {
                        Picker(settings.language.text(.language), selection: $settings.language) {
                            Text("中文").tag(AppLanguage.zh)
                            Text("English").tag(AppLanguage.en)
                        }
                        .pickerStyle(.segmented)
                        Picker(settings.language.text(.theme), selection: $settings.appTheme) {
                            Text(settings.language.text(.dark)).tag(AppTheme.dark)
                            Text(settings.language.text(.light)).tag(AppTheme.light)
                            Text(settings.language.text(.system)).tag(AppTheme.system)
                        }
                        .pickerStyle(.segmented)
                    }

                    if let validationMessage {
                        Text(validationMessage)
                            .foregroundStyle(palette.warning)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            #else
            Form {
                Section {
                    HStack {
                        Label(settings.language.text(.deepseekApiKey), systemImage: "key.fill")
                        Spacer()
                        Text(dashboard.apiKeyConfigured ? settings.language.text(.configuredLocally) : settings.language.text(.notConfigured))
                            .foregroundStyle(dashboard.apiKeyConfigured ? palette.accent : palette.muted)
                    }
                    SecureField(settings.language.text(.enterNewApiKey), text: $apiKeyInput)
                        .textContentType(.password)
                    Button(role: .destructive) {
                        clearKey()
                    } label: {
                        Label(settings.language.text(.clearKey), systemImage: "trash")
                    }
                    .disabled(!dashboard.apiKeyConfigured)
                } header: {
                    Text(settings.language.text(.deepseekApiKey))
                }

                Section {
                    TextField("80.00", text: $creditInput)
                    Stepper(value: $settings.gaugeMaxAmount, in: 100...1000, step: 100) {
                        HStack {
                            Text(settings.language.text(.gaugeRange))
                            Spacer()
                            Text("MAX \(Int(settings.gaugeMaxAmount)) CNY")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Picker(settings.language.text(.refreshInterval), selection: $settings.refreshInterval) {
                        ForEach(RefreshInterval.allCases) { interval in
                            Text("\(interval.seconds)s").tag(interval)
                        }
                    }
                } header: {
                    Text(settings.language.text(.initialTotalCredit))
                } footer: {
                    Text(settings.language.text(.estimateNote))
                }

                Section {
                    Picker(settings.language.text(.language), selection: $settings.language) {
                        Text("中文").tag(AppLanguage.zh)
                        Text("English").tag(AppLanguage.en)
                    }
                    Picker(settings.language.text(.theme), selection: $settings.appTheme) {
                        Text(settings.language.text(.dark)).tag(AppTheme.dark)
                        Text(settings.language.text(.light)).tag(AppTheme.light)
                        Text(settings.language.text(.system)).tag(AppTheme.system)
                    }
                }

                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(palette.warning)
                }
            }
            #endif
        }
        .navigationTitle(settings.language.text(.settings))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(saveButtonTitle) {
                    save()
                }
                .disabled(saveState == .saving)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(settings.language == .zh ? "完成" : "Done") { dismiss() }
            }
        }
        .onAppear {
            if let initialTotalCredit = settings.initialTotalCredit {
                creditInput = initialTotalCredit.formatted(.number.precision(.fractionLength(2)))
            }
        }
    }

    private var saveButtonTitle: String {
        switch saveState {
        case .idle:
            return settings.language.text(.save)
        case .saving:
            return settings.language.text(.saving)
        case .saved:
            return settings.language.text(.saved)
        case .failed:
            return settings.language.text(.save)
        }
    }

    private func save() {
        validationMessage = nil
        let trimmedCredit = creditInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let credit: Double?
        if trimmedCredit.isEmpty {
            credit = nil
        } else if let parsed = Double(trimmedCredit), parsed >= 0 {
            credit = parsed
        } else {
            validationMessage = settings.language.text(.invalidCredit)
            return
        }

        saveState = .saving
        Task {
            do {
                try await dashboard.saveSettings(apiKey: apiKeyInput, initialTotalCredit: credit)
                apiKeyInput = ""
                saveState = .saved
                try? await Task.sleep(for: .milliseconds(800))
                saveState = .idle
            } catch {
                saveState = .failed(error.localizedDescription)
                validationMessage = error.localizedDescription
            }
        }
    }

    private func clearKey() {
        do {
            try dashboard.clearAPIKey()
        } catch {
            validationMessage = error.localizedDescription
        }
    }
}

#if os(macOS)
private struct MacSettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
#endif
