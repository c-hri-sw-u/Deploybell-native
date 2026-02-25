import Foundation

// MARK: - Config Models

struct SoundConfig: Codable, Equatable {
    var enabled: Bool
    var success: Bool
    var error: Bool
}

struct ProjectInfo: Codable, Identifiable, Equatable {
    let id: String
    let name: String
}

struct AppConfig: Codable, Equatable {
    var token: String
    var projects: [ProjectInfo]
    var pollInterval: Int
    var sound: SoundConfig

    static let `default` = AppConfig(
        token: "",
        projects: [],
        pollInterval: 5,
        sound: SoundConfig(enabled: true, success: true, error: true)
    )
}

// MARK: - Vercel API Models

struct VercelProject: Codable, Identifiable {
    let id: String
    let name: String
}

enum DeploymentState: String, Codable {
    case QUEUED, BUILDING, ERROR, INITIALIZING, READY, CANCELED
}

struct DeploymentMeta: Codable {
    let githubCommitRef: String?
    let githubCommitSha: String?
    let githubCommitMessage: String?
}

struct VercelDeployment: Codable, Identifiable {
    let uid: String
    let name: String
    let url: String?
    let created: TimeInterval
    let state: DeploymentState
    let meta: DeploymentMeta?

    var id: String { uid }
}

// MARK: - API Response Wrappers

struct ProjectsResponse: Codable {
    let projects: [VercelProject]
}

struct DeploymentsResponse: Codable {
    let deployments: [VercelDeployment]
}
