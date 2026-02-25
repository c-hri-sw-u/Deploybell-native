import SwiftUI

struct SetupView: View {
    @EnvironmentObject var configManager: ConfigManager
    let onComplete: () -> Void

    @State private var token = ""
    @State private var step = 1
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var projects: [VercelProject] = []
    @State private var selectedIds: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Deploybell Setup")
                .font(.title3)
                .fontWeight(.semibold)

            if step == 1 {
                tokenStep
            } else {
                projectStep
            }
        }
        .padding(16)
    }

    // MARK: - Step 1: Token

    private var tokenStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter your Vercel Personal Access Token.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Link("Get Token →", destination: URL(string: "https://vercel.com/account/tokens")!)
                    .font(.callout)
            }

            SecureField("paste_token_here...", text: $token)
                .textFieldStyle(.roundedBorder)
                .onSubmit { validate() }

            if let error = errorMessage {
                Text(error).font(.callout).foregroundStyle(.red)
            }

            HoverButton(title: isLoading ? "Validating..." : "Next", isLoading: isLoading) {
                validate()
            }
            .disabled(token.isEmpty || isLoading)
        }
    }

    // MARK: - Step 2: Projects

    private var projectStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select projects to monitor (max 8).")
                .font(.callout)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(projects) { project in
                        ProjectSelectionRow(
                            name: project.name,
                            isSelected: selectedIds.contains(project.id)
                        ) {
                            toggleProject(project.id)
                        }
                    }
                }
            }
            .frame(maxHeight: 220)

            if let error = errorMessage {
                Text(error).font(.callout).foregroundStyle(.red)
            }

            HoverButton(
                title: "Start Monitoring (\(selectedIds.count))",
                isLoading: isLoading
            ) {
                finish()
            }
            .disabled(selectedIds.isEmpty || isLoading)
        }
    }

    // MARK: - Actions

    private func validate() {
        isLoading = true
        errorMessage = nil
        Task {
            let isValid = await VercelAPI.validateToken(token)
            if !isValid {
                await MainActor.run {
                    errorMessage = "Invalid or expired token."
                    isLoading = false
                }
                return
            }
            do {
                let fetched = try await VercelAPI.listProjects(token: token)
                if fetched.isEmpty { throw VercelAPIError.noProjects }
                await MainActor.run {
                    projects = fetched
                    selectedIds = Set(fetched.prefix(5).map(\.id))
                    step = 2
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func toggleProject(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else if selectedIds.count < 8 {
            selectedIds.insert(id)
        }
    }

    private func finish() {
        isLoading = true
        errorMessage = nil
        let selected = projects.filter { selectedIds.contains($0.id) }
        let newConfig = AppConfig(
            token: token,
            projects: selected.map { ProjectInfo(id: $0.id, name: $0.name) },
            pollInterval: 5,
            sound: SoundConfig(enabled: true, success: true, error: true)
        )
        do {
            try configManager.saveConfig(newConfig)
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Project Selection Row

struct ProjectSelectionRow: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                Text(name)
                    .font(.callout)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? Color.blue.opacity(0.15)
                    : (isHovered ? Color.white.opacity(0.15) : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Reusable Hover Button

struct HoverButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView().controlSize(.small)
                }
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(isHovered ? Color.accentColor.opacity(0.75) : Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
