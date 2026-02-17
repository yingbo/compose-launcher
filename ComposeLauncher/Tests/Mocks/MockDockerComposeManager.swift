import Foundation
@testable import ComposeLauncherCore

@MainActor
class MockDockerComposeManager: DockerComposeManaging {
    @Published var logs: [LogEntry] = []

    private var _runningFiles: Set<UUID> = []
    private var _services: [UUID: [String]] = [:]
    private var _runningServices: [UUID: [String]] = [:]
    private var _detailedRunningServices: [UUID: [ServiceInfo]] = [:]

    // Call tracking for test assertions
    var startComposeCallCount = 0
    var stopComposeCallCount = 0
    var lastStartedFile: ComposeFile?
    var lastStoppedFile: ComposeFile?
    var configuredMaxLogLines: Int?
    var configuredDockerPath: String?

    // Configurable behavior
    var shouldThrowOnStart = false
    var startError: Error = NSError(domain: "MockDocker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])

    func configure(maxLogLines: Int, dockerPath: String) {
        configuredMaxLogLines = maxLogLines
        configuredDockerPath = dockerPath
    }

    func startCompose(for file: ComposeFile) async throws {
        startComposeCallCount += 1
        lastStartedFile = file
        if shouldThrowOnStart {
            throw startError
        }
        _runningFiles.insert(file.id)
        logs.append(LogEntry(composeFileId: file.id, message: "Mock: Starting docker compose..."))
    }

    func stopCompose(for file: ComposeFile) async {
        stopComposeCallCount += 1
        lastStoppedFile = file
        _runningFiles.remove(file.id)
        logs.append(LogEntry(composeFileId: file.id, message: "Mock: Containers stopped"))
    }

    func isRunning(_ file: ComposeFile) -> Bool {
        _runningFiles.contains(file.id)
    }

    func getServices(for file: ComposeFile) async -> [String] {
        _services[file.id] ?? ["web", "db", "redis"]
    }

    func getRunningServices(for file: ComposeFile) async -> [String] {
        _runningServices[file.id] ?? []
    }

    var shouldThrowOnDetailedServices = false
    var detailedServicesError: Error = NSError(domain: "MockDocker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock detailed services error"])

    func getDetailedRunningServices(for file: ComposeFile) async throws -> [ServiceInfo] {
        if shouldThrowOnDetailedServices {
            throw detailedServicesError
        }
        return _detailedRunningServices[file.id] ?? []
    }

    func clearLogs(for fileId: UUID? = nil) {
        if let fileId = fileId {
            logs.removeAll { $0.composeFileId == fileId }
        } else {
            logs.removeAll()
        }
    }

    // MARK: - Test helpers

    func setServices(_ services: [String], for fileId: UUID) {
        _services[fileId] = services
    }

    func setRunningServices(_ services: [String], for fileId: UUID) {
        _runningServices[fileId] = services
    }

    func setDetailedRunningServices(_ services: [ServiceInfo], for fileId: UUID) {
        _detailedRunningServices[fileId] = services
    }

    func markAsRunning(_ fileId: UUID) {
        _runningFiles.insert(fileId)
    }
}
