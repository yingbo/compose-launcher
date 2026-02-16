import XCTest
@testable import ComposeLauncherCore

@MainActor
final class MockDockerComposeManagerTests: XCTestCase {
    var sut: MockDockerComposeManager!
    var testFile: ComposeFile!

    override func setUp() async throws {
        sut = MockDockerComposeManager()
        testFile = ComposeFile(name: "test", path: "/tmp/docker-compose.yml")
    }

    // MARK: - isRunning

    func testIsRunningReturnsFalseInitially() {
        XCTAssertFalse(sut.isRunning(testFile))
    }

    func testIsRunningReturnsTrueAfterStart() async throws {
        try await sut.startCompose(for: testFile)
        XCTAssertTrue(sut.isRunning(testFile))
    }

    func testIsRunningReturnsFalseAfterStop() async throws {
        try await sut.startCompose(for: testFile)
        await sut.stopCompose(for: testFile)
        XCTAssertFalse(sut.isRunning(testFile))
    }

    // MARK: - Logging

    func testStartAddsLogEntry() async throws {
        try await sut.startCompose(for: testFile)
        XCTAssertEqual(sut.logs.count, 1)
        XCTAssertTrue(sut.logs[0].message.contains("Starting"))
        XCTAssertEqual(sut.logs[0].composeFileId, testFile.id)
    }

    func testStopAddsLogEntry() async throws {
        try await sut.startCompose(for: testFile)
        await sut.stopCompose(for: testFile)
        XCTAssertEqual(sut.logs.count, 2)
        XCTAssertTrue(sut.logs[1].message.contains("stopped"))
    }

    func testClearLogsForSpecificFile() async throws {
        let otherFile = ComposeFile(name: "other", path: "/tmp/other.yml")
        try await sut.startCompose(for: testFile)
        try await sut.startCompose(for: otherFile)
        XCTAssertEqual(sut.logs.count, 2)

        sut.clearLogs(for: testFile.id)
        XCTAssertEqual(sut.logs.count, 1)
        XCTAssertEqual(sut.logs[0].composeFileId, otherFile.id)
    }

    func testClearAllLogs() async throws {
        try await sut.startCompose(for: testFile)
        let otherFile = ComposeFile(name: "other", path: "/tmp/other.yml")
        try await sut.startCompose(for: otherFile)
        XCTAssertEqual(sut.logs.count, 2)

        sut.clearLogs()
        XCTAssertTrue(sut.logs.isEmpty)
    }

    // MARK: - Services

    func testGetServicesReturnsDefaults() async {
        let services = await sut.getServices(for: testFile)
        XCTAssertEqual(services, ["web", "db", "redis"])
    }

    func testGetServicesReturnsConfigured() async {
        sut.setServices(["api", "worker"], for: testFile.id)
        let services = await sut.getServices(for: testFile)
        XCTAssertEqual(services, ["api", "worker"])
    }

    func testGetRunningServicesReturnsEmptyByDefault() async {
        let services = await sut.getRunningServices(for: testFile)
        XCTAssertTrue(services.isEmpty)
    }

    func testGetRunningServicesReturnsConfigured() async {
        sut.setRunningServices(["web", "db"], for: testFile.id)
        let services = await sut.getRunningServices(for: testFile)
        XCTAssertEqual(services, ["web", "db"])
    }

    // MARK: - Error handling

    func testStartThrowsWhenConfigured() async {
        sut.shouldThrowOnStart = true
        do {
            try await sut.startCompose(for: testFile)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertFalse(sut.isRunning(testFile))
        }
    }

    // MARK: - Call tracking

    func testCallCountTracking() async throws {
        try await sut.startCompose(for: testFile)
        XCTAssertEqual(sut.startComposeCallCount, 1)
        XCTAssertEqual(sut.lastStartedFile, testFile)

        await sut.stopCompose(for: testFile)
        XCTAssertEqual(sut.stopComposeCallCount, 1)
        XCTAssertEqual(sut.lastStoppedFile, testFile)
    }

    // MARK: - Configure

    func testConfigure() {
        sut.configure(maxLogLines: 500, dockerPath: "/usr/local/bin/docker")
        XCTAssertEqual(sut.configuredMaxLogLines, 500)
        XCTAssertEqual(sut.configuredDockerPath, "/usr/local/bin/docker")
    }

    // MARK: - Multiple files

    func testMultipleFilesIndependent() async throws {
        let file2 = ComposeFile(name: "second", path: "/tmp/second.yml")

        try await sut.startCompose(for: testFile)
        try await sut.startCompose(for: file2)

        XCTAssertTrue(sut.isRunning(testFile))
        XCTAssertTrue(sut.isRunning(file2))

        await sut.stopCompose(for: testFile)
        XCTAssertFalse(sut.isRunning(testFile))
        XCTAssertTrue(sut.isRunning(file2))
    }
}
