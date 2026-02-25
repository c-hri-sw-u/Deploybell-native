import SwiftUI

enum AppView {
    case setup, dashboard, settings
}

struct ContentView: View {
    @EnvironmentObject var configManager: ConfigManager
    @EnvironmentObject var poller: DeploymentPoller
    @State private var currentView: AppView = .setup

    var body: some View {
        Group {
            switch currentView {
            case .setup:
                SetupView {
                    currentView = .dashboard
                }
                .frame(width: 280, height: 360)
            case .dashboard:
                DashboardView(onSettings: {
                    currentView = .settings
                })
                .frame(width: 280) // height adapts to entry count
            case .settings:
                SettingsView(onBack: {
                    currentView = .dashboard
                })
                .frame(width: 280, height: 420)
            }
        }
        .onAppear {
            currentView = configManager.isConfigured ? .dashboard : .setup
        }
    }
}
