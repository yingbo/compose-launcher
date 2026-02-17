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

    // MARK: - Detailed Running Services

    func testGetDetailedRunningServicesReturnsEmptyByDefault() async {
        let services = await sut.getDetailedRunningServices(for: testFile)
        XCTAssertTrue(services.isEmpty)
    }

    func testGetDetailedRunningServicesReturnsConfigured() async {
        let info = ServiceInfo(
            Service: "web",
            State: "running",
            Status: "Up 2 hours",
            Name: "proj-web-1",
            Ports: "0.0.0.0:8080->80/tcp",
            Publishers: [
                PortPublisher(URL: "0.0.0.0", TargetPort: 80, PublishedPort: 8080, Protocol: "tcp")
            ],
            composeFileId: testFile.id
        )
        sut.setDetailedRunningServices([info], for: testFile.id)

        let services = await sut.getDetailedRunningServices(for: testFile)
        XCTAssertEqual(services.count, 1)
        XCTAssertEqual(services[0].Service, "web")
        XCTAssertEqual(services[0].Publishers.count, 1)
        XCTAssertEqual(services[0].Publishers[0].PublishedPort, 8080)
    }

    func testGetDetailedRunningServicesMultipleFiles() async {
        let otherFile = ComposeFile(name: "other", path: "/tmp/other.yml")

        let info1 = ServiceInfo(Service: "web", State: "running", Name: "p1-web-1", composeFileId: testFile.id)
        let info2 = ServiceInfo(Service: "api", State: "running", Name: "p2-api-1", composeFileId: otherFile.id)

        sut.setDetailedRunningServices([info1], for: testFile.id)
        sut.setDetailedRunningServices([info2], for: otherFile.id)

        let services1 = await sut.getDetailedRunningServices(for: testFile)
        let services2 = await sut.getDetailedRunningServices(for: otherFile)
        XCTAssertEqual(services1.count, 1)
        XCTAssertEqual(services1[0].Service, "web")
        XCTAssertEqual(services2.count, 1)
        XCTAssertEqual(services2[0].Service, "api")
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
