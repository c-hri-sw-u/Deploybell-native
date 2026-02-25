import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var configManager: ConfigManager
    @EnvironmentObject var poller: DeploymentPoller
    let onSettings: () -> Void

    @State private var gearHovered = false
    @State private var quitHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Deploybell")
                        .font(.callout)
                        .fontWeight(.semibold)
                }

                Spacer()

                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundStyle(gearHovered ? .primary : .secondary)
                        .padding(5)
                        .background(gearHovered ? Color.white.opacity(0.15) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .onHover { gearHovered = $0 }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Project list
            if configManager.config.projects.isEmpty {
                Text("No projects configured.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(configManager.config.projects) { project in
                        ProjectRowView(
                            project: project,
                            deployment: poller.deployments[project.id]
                        )
                    }
                }
                .padding(.vertical, 4)
            }

            // Bottom: Divider + Quit
            Divider()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit Deploybell")
                    .font(.callout)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .foregroundStyle(quitHovered ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .onHover { quitHovered = $0 }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }
}
