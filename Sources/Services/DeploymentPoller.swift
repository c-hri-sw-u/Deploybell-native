import Foundation
import AppKit
import Combine

class DeploymentPoller: ObservableObject {
    @Published var deployments: [String: VercelDeployment] = [:]
    @Published var statusIcon: String = "bell.fill"

    private var timer: AnyCancellable?
    private var previousStates: [String: DeploymentState] = [:]
    private var configCancellable: AnyCancellable?
    private weak var configManager: ConfigManager?

    func bind(to configManager: ConfigManager) {
        self.configManager = configManager
        configCancellable = configManager.$config
            .receive(on: RunLoop.main)
            .sink { [weak self] config in
                self?.restartPolling(config: config)
            }
    }

    private func restartPolling(config: AppConfig) {
        timer?.cancel()
        guard !config.token.isEmpty, !config.projects.isEmpty else { return }

        Task { @MainActor in await poll(config: config) }

        let interval = TimeInterval(max(config.pollInterval, 1))
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let cfg = self?.configManager?.config else { return }
                    await self?.poll(config: cfg)
                }
            }
    }

    @MainActor
    private func poll(config: AppConfig) async {
        guard !config.token.isEmpty else { return }

        var anyBuilding = false
        var anyError = false

        await withTaskGroup(of: (String, VercelDeployment?).self) { group in
            for project in config.projects {
                group.addTask {
                    do {
                        let dep = try await VercelAPI.getLatestDeployment(
                            token: config.token, projectId: project.id
                        )
                        return (project.id, dep)
                    } catch {
                        return (project.id, nil)
                    }
                }
            }

            for await (projectId, deployment) in group {
                guard let deployment = deployment else { continue }

                let prevState = previousStates[projectId]
                if let prev = prevState, prev != deployment.state {
                    if deployment.state == .READY && prev == .BUILDING {
                        playSound(success: true, config: config)
                    } else if deployment.state == .ERROR && prev == .BUILDING {
                        playSound(success: false, config: config)
                    }
                }

                previousStates[projectId] = deployment.state
                deployments[projectId] = deployment

                if deployment.state == .BUILDING || deployment.state == .QUEUED || deployment.state == .INITIALIZING {
                    anyBuilding = true
                }
                if deployment.state == .ERROR { anyError = true }
            }
        }

        if anyError {
            statusIcon = "exclamationmark.triangle.fill"
        } else if anyBuilding {
            statusIcon = "bell.badge.fill"
        } else {
            statusIcon = "bell.fill"
        }
    }

    private func playSound(success: Bool, config: AppConfig) {
        guard config.sound.enabled else { return }
        if success && config.sound.success {
            NSSound(named: .init("Glass"))?.play()
        } else if !success && config.sound.error {
            NSSound(named: .init("Basso"))?.play()
        }
    }
}
