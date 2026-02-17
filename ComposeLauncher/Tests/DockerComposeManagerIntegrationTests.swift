import XCTest
@testable import ComposeLauncherCore

/// Integration tests that require real Docker.
/// Skipped in CI (when MOCK_DOCKER=1) and when Docker is not installed.
@MainActor
final class DockerComposeManagerIntegrationTests: XCTestCase {
    var sut: DockerComposeManager!

    override func setUp() async throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["MOCK_DOCKER"] == "1",
            "Skipping integration tests in mock mode (MOCK_DOCKER=1)"
        )

        let dockerExists = FileManager.default.isExecutableFile(atPath: "/opt/homebrew/bin/docker")
            || FileManager.default.isExecutableFile(atPath: "/usr/local/bin/docker")

        try XCTSkipUnless(dockerExists, "Docker not found on this machine")

        sut = DockerComposeManager()
        let dockerPath: String
        if FileManager.default.isExecutableFile(atPath: "/opt/homebrew/bin/docker") {
            dockerPath = "/opt/homebrew/bin/docker"
        } else {
            dockerPath = "/usr/local/bin/docker"
        }
        sut.configure(maxLogLines: 1000, dockerPath: dockerPath)
    }

    func testGetServicesWithSampleCompose() async throws {
        // Find sample-compose/mongo.yml relative to this test file's package
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // ComposeLauncher/
            .deletingLastPathComponent() // repo root

        let samplePath = projectRoot.appendingPathComponent("sample-compose/mongo.yml").path

        try XCTSkipUnless(
            FileManager.default.fileExists(atPath: samplePath),
            "sample-compose/mongo.yml not found at \(samplePath)"
        )

        let file = ComposeFile(name: "mongo", path: samplePath)
        let services = await sut.getServices(for: file)
        XCTAssertFalse(services.isEmpty, "Expected at least one service in mongo.yml")
    }

    func testStartWithInvalidDockerPathThrows() async {
        sut.configure(maxLogLines: 1000, dockerPath: "/nonexistent/docker")
        let file = ComposeFile(name: "test", path: "/tmp/nonexistent.yml")

        do {
            try await sut.startCompose(for: file)
            XCTFail("Expected error for invalid docker path")
        } catch {
            // Expected: Docker executable not found
            XCTAssertTrue(sut.logs.contains { $0.isError })
        }
    }

    func testIsRunningReturnsFalseWhenNotStarted() {
        let file = ComposeFile(name: "test", path: "/tmp/test.yml")
        XCTAssertFalse(sut.isRunning(file))
    }

    func testClearLogsWorks() {
        let fileId = UUID()
        // Manually verify clearLogs doesn't crash on empty state
        sut.clearLogs(for: fileId)
        sut.clearLogs()
        XCTAssertTrue(sut.logs.isEmpty)
    }
}
