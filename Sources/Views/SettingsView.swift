import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var configManager: ConfigManager
    let onBack: () -> Void

    @State private var localConfig: AppConfig = .default
    @State private var backHovered = false
    @State private var quitHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .medium))
                        .padding(5)
                        .background(backHovered ? Color.white.opacity(0.15) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .onHover { backHovered = $0 }

                Text("Settings")
                    .font(.callout)
                    .fontWeight(.medium)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Settings form
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Token
                    settingsSection("VERCEL TOKEN") {
                        SecureField("Token", text: $localConfig.token)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Polling
                    settingsSection("POLLING INTERVAL") {
                        Picker("", selection: $localConfig.pollInterval) {
                            Text("Every 5 seconds").tag(5)
                            Text("Every 10 seconds").tag(10)
                            Text("Every 15 seconds").tag(15)
                            Text("Every 30 seconds").tag(30)
                            Text("Every 1 minute").tag(60)
                        }
                        .labelsHidden()

                        if let warning = pollWarning {
                            Text(warning)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    // Sound
                    settingsSection("SOUND NOTIFICATIONS") {
                        VStack(spacing: 0) {
                            toggleRow("Enable Sounds", isOn: $localConfig.sound.enabled)
                            Divider()
                            toggleRow("Success Chime", isOn: $localConfig.sound.success)
                                .opacity(localConfig.sound.enabled ? 1 : 0.5)
                                .disabled(!localConfig.sound.enabled)
                            Divider()
                            toggleRow("Error Alert", isOn: $localConfig.sound.error)
                                .opacity(localConfig.sound.enabled ? 1 : 0.5)
                                .disabled(!localConfig.sound.enabled)
                        }
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    // Projects
                    settingsSection("MONITORED PROJECTS") {
                        HStack {
                            Text("\(localConfig.projects.count) project(s) tracked.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Button("Reset") {
                                localConfig.token = ""
                                localConfig.projects = []
                            }
                            .font(.callout)
                        }
                    }
                }
                .padding(14)
            }
            .frame(maxHeight: 320)

            Divider()

            // Bottom buttons
            VStack(spacing: 6) {
                HoverButton(title: "Save Changes") { save() }

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit Deploybell")
                        .font(.callout)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .foregroundStyle(quitHovered ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .onHover { quitHovered = $0 }
            }
            .padding(14)
        }
        .onAppear {
            localConfig = configManager.config
        }
    }

    private var pollWarning: String? {
        let rate = Double(localConfig.projects.count) * (60.0 / Double(localConfig.pollInterval))
        if rate > 80 {
            return "Warning: \(Int(rate)) req/min is close to Vercel's ~100 req/min limit."
        }
        return nil
    }

    private func save() {
        do {
            try configManager.saveConfig(localConfig)
            onBack()
        } catch {
            print("Failed to save: \(error)")
        }
    }

    @ViewBuilder
    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.5)
            content()
        }
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.callout)
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
