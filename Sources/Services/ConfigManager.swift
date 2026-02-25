import Foundation
import SwiftUI

class ConfigManager: ObservableObject {
    @Published var config: AppConfig = .default
    @Published var isLoading = true

    private let configURL: URL

    var isConfigured: Bool {
        !config.token.isEmpty && !config.projects.isEmpty
    }

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("com.deploybell.app")
        self.configURL = appDir.appendingPathComponent("config.json")
        loadConfig()
    }

    func loadConfig() {
        isLoading = true
        defer { isLoading = false }

        guard FileManager.default.fileExists(atPath: configURL.path) else {
            config = .default
            return
        }

        do {
            let data = try Data(contentsOf: configURL)
            config = try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            print("Failed to read config: \(error)")
            config = .default
        }
    }

    func saveConfig(_ newConfig: AppConfig) throws {
        let dir = configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(newConfig)
        try data.write(to: configURL)
        config = newConfig
    }
}
