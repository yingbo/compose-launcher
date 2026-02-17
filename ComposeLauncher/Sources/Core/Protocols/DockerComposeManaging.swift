import Foundation

@MainActor
public protocol DockerComposeManaging: ObservableObject {
    var logs: [LogEntry] { get set }

    func startCompose(for file: ComposeFile) async throws
    func stopCompose(for file: ComposeFile) async
    func isRunning(_ file: ComposeFile) -> Bool
    func getServices(for file: ComposeFile) async -> [String]
    func getRunningServices(for file: ComposeFile) async -> [String]
    func getDetailedRunningServices(for file: ComposeFile) async -> [ServiceInfo]
    func clearLogs(for fileId: UUID?)
    func configure(maxLogLines: Int, dockerPath: String)
}

public extension DockerComposeManaging {
    func clearLogs() {
        clearLogs(for: nil)
    }
}
