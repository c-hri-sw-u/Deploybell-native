import SwiftUI
import AppKit

struct ProjectRowView: View {
    let project: ProjectInfo
    let deployment: VercelDeployment?

    @State private var timeText = ""
    @State private var isHovered = false

    var body: some View {
        Button(action: openURL) {
            HStack(spacing: 10) {
                StatusDotView(state: deployment?.state ?? .QUEUED)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(project.name)
                            .font(.callout)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        Spacer()

                        Text(timeText)
                            .font(.caption)
                            .foregroundStyle(isBuilding ? .orange : .secondary)
                    }

                    if let meta = deployment?.meta {
                        HStack(spacing: 4) {
                            Text(meta.githubCommitRef ?? "main")
                                .lineLimit(1)
                            if let sha = meta.githubCommitSha {
                                Text("·").foregroundStyle(.tertiary)
                                Text(String(sha.prefix(7)))
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontDesign(.monospaced)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isHovered ? Color.white.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .padding(.horizontal, 4)
        .onAppear { updateTime() }
        .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
            updateTime()
        }
    }

    private var isBuilding: Bool {
        deployment?.state == .BUILDING || deployment?.state == .QUEUED
    }

    private func updateTime() {
        guard let deployment = deployment else {
            timeText = "Loading..."
            return
        }
        switch deployment.state {
        case .READY, .ERROR, .CANCELED:
            timeText = timeSince(deployment.created)
        default:
            timeText = deployment.state.rawValue.lowercased()
        }
    }

    private func openURL() {
        guard let urlString = deployment?.url,
              let url = URL(string: "https://\(urlString)") else { return }
        NSWorkspace.shared.open(url)
    }

    private func timeSince(_ timestampMs: TimeInterval) -> String {
        let seconds = Int(Date().timeIntervalSince1970 - timestampMs / 1000.0)
        if seconds < 60 { return "\(seconds)s ago" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        if seconds < 2592000 { return "\(seconds / 86400)d ago" }
        if seconds < 31536000 { return "\(seconds / 2592000)mo ago" }
        return "\(seconds / 31536000)y ago"
    }
}

// MARK: - Status Dot

struct StatusDotView: View {
    let state: DeploymentState

    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 8, height: 8)
            .shadow(color: dotColor.opacity(0.5), radius: 4)
    }

    private var dotColor: Color {
        switch state {
        case .READY: return .green
        case .ERROR: return .red
        case .BUILDING, .QUEUED, .INITIALIZING: return .orange
        case .CANCELED: return .gray
        }
    }
}
