import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct DeploybellApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var configManager = ConfigManager()
    @StateObject private var poller = DeploymentPoller()
    @State private var pollerBound = false

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(configManager)
                .environmentObject(poller)
                .preferredColorScheme(.dark)
                .onAppear {
                    if !pollerBound {
                        poller.bind(to: configManager)
                        pollerBound = true
                    }
                }
        } label: {
            Image(systemName: poller.statusIcon)
        }
        .menuBarExtraStyle(.window)
    }
}
