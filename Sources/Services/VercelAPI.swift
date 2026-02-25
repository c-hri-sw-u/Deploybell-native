import Foundation

enum VercelAPIError: LocalizedError {
    case invalidResponse
    case httpError(Int, String)
    case invalidToken
    case noProjects

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from Vercel API"
        case .httpError(let code, let msg): return "HTTP \(code): \(msg)"
        case .invalidToken: return "Invalid or expired token"
        case .noProjects: return "No Vercel projects found"
        }
    }
}

struct VercelAPI {
    static let baseURL = "https://api.vercel.com"

    static func fetch<T: Decodable>(_ endpoint: String, token: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw VercelAPIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VercelAPIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw VercelAPIError.httpError(
                httpResponse.statusCode,
                HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    static func validateToken(_ token: String) async -> Bool {
        do {
            let _: ProjectsResponse = try await fetch("/v9/projects?limit=1", token: token)
            return true
        } catch {
            return false
        }
    }

    static func listProjects(token: String) async throws -> [VercelProject] {
        let response: ProjectsResponse = try await fetch("/v9/projects", token: token)
        return response.projects
    }

    static func getLatestDeployment(token: String, projectId: String) async throws -> VercelDeployment? {
        let response: DeploymentsResponse = try await fetch(
            "/v6/deployments?projectId=\(projectId)&limit=1", token: token
        )
        return response.deployments.first
    }
}
