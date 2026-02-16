import XCTest
@testable import ComposeLauncherCore

@MainActor
final class SettingsManagerTests: XCTestCase {
    var tempDir: URL!
    var settingsURL: URL!
    var sut: SettingsManager!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ComposeLauncherTests-\(UUID().uuidString)")
        settingsURL = tempDir.appendingPathComponent("settings.yaml")
        sut = SettingsManager(settingsURL: settingsURL)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testLoadDefaultsWhenNoFile() {
        XCTAssertEqual(sut.settings.maxLogLines, 100_000)
        XCTAssertTrue(sut.settings.composeFiles.isEmpty)
        XCTAssertEqual(sut.settings.sidebarDisplayMode, .tree)
    }

    func testSaveAndLoadRoundTrip() {
        sut.settings.maxLogLines = 500
        sut.saveSettings()

        let loaded = SettingsManager(settingsURL: settingsURL)
        XCTAssertEqual(loaded.settings.maxLogLines, 500)
    }

    func testAddComposeFile() {
        let file = ComposeFile(name: "test", path: "/tmp/docker-compose.yml")
        sut.addComposeFile(file)
        XCTAssertEqual(sut.settings.composeFiles.count, 1)
        XCTAssertEqual(sut.settings.composeFiles.first?.name, "test")

        // Verify persistence
        let loaded = SettingsManager(settingsURL: settingsURL)
        XCTAssertEqual(loaded.settings.composeFiles.count, 1)
    }

    func testRemoveComposeFile() {
        let file = ComposeFile(name: "test", path: "/tmp/docker-compose.yml")
        sut.addComposeFile(file)
        sut.removeComposeFile(file)
        XCTAssertTrue(sut.settings.composeFiles.isEmpty)

        let loaded = SettingsManager(settingsURL: settingsURL)
        XCTAssertTrue(loaded.settings.composeFiles.isEmpty)
    }

    func testUpdateComposeFile() {
        var file = ComposeFile(name: "original", path: "/tmp/docker-compose.yml")
        sut.addComposeFile(file)

        file.name = "updated"
        sut.updateComposeFile(file)
        XCTAssertEqual(sut.settings.composeFiles.first?.name, "updated")
    }

    func testUpdateMaxLogLines() {
        sut.updateMaxLogLines(999)
        XCTAssertEqual(sut.settings.maxLogLines, 999)

        let loaded = SettingsManager(settingsURL: settingsURL)
        XCTAssertEqual(loaded.settings.maxLogLines, 999)
    }

    func testUpdateDockerPath() {
        sut.updateDockerPath("/custom/path/docker")
        XCTAssertEqual(sut.settings.dockerComposePath, "/custom/path/docker")

        let loaded = SettingsManager(settingsURL: settingsURL)
        XCTAssertEqual(loaded.settings.dockerComposePath, "/custom/path/docker")
    }

    func testUpdateSidebarDisplayMode() {
        sut.updateSidebarDisplayMode(.flat)
        XCTAssertEqual(sut.settings.sidebarDisplayMode, .flat)

        let loaded = SettingsManager(settingsURL: settingsURL)
        XCTAssertEqual(loaded.settings.sidebarDisplayMode, .flat)
    }

    func testMultipleFilesIndependentRemoval() {
        let file1 = ComposeFile(name: "a", path: "/tmp/a.yml")
        let file2 = ComposeFile(name: "b", path: "/tmp/b.yml")
        let file3 = ComposeFile(name: "c", path: "/tmp/c.yml")

        sut.addComposeFile(file1)
        sut.addComposeFile(file2)
        sut.addComposeFile(file3)
        XCTAssertEqual(sut.settings.composeFiles.count, 3)

        sut.removeComposeFile(file2)
        XCTAssertEqual(sut.settings.composeFiles.count, 2)
        XCTAssertEqual(sut.settings.composeFiles.map { $0.name }, ["a", "c"])
    }

    func testCorruptYAMLFallsBackToDefaults() throws {
        // Write invalid YAML
        try "{{{{invalid yaml!!!!".write(to: settingsURL, atomically: true, encoding: .utf8)

        let loaded = SettingsManager(settingsURL: settingsURL)
        // Should fall back to defaults rather than crash
        XCTAssertEqual(loaded.settings.maxLogLines, 100_000)
    }
}
