import XCTest
@testable import ComposeLauncherCore

final class ComposeFileTests: XCTestCase {
    func testInitDefaults() {
        let file = ComposeFile(name: "test", path: "/tmp/docker-compose.yml")
        XCTAssertFalse(file.isRunning)
        XCTAssertNil(file.envFilePath)
        XCTAssertFalse(file.id.uuidString.isEmpty)
    }

    func testDisplayNameReturnsNameWhenNotEmpty() {
        let file = ComposeFile(name: "my-project", path: "/tmp/docker-compose.yml")
        XCTAssertEqual(file.displayName, "my-project")
    }

    func testDisplayNameReturnsFolderNameWhenEmpty() {
        let file = ComposeFile(name: "", path: "/Users/test/my-project/docker-compose.yml")
        XCTAssertEqual(file.displayName, "my-project")
    }

    func testCodableRoundTrip() throws {
        let original = ComposeFile(
            name: "test-project",
            path: "/tmp/compose.yml",
            envFilePath: "/tmp/.env"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ComposeFile.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testHashable() {
        let file1 = ComposeFile(name: "a", path: "/tmp/a.yml")
        let file2 = ComposeFile(name: "b", path: "/tmp/b.yml")
        let set: Set<ComposeFile> = [file1, file2, file1]
        XCTAssertEqual(set.count, 2)
    }
}

final class LogEntryTests: XCTestCase {
    func testFormattedTimestamp() {
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01 00:00:00 UTC
        let entry = LogEntry(
            timestamp: date,
            composeFileId: UUID(),
            message: "test"
        )
        let timestamp = entry.formattedTimestamp
        // Format is HH:mm:ss.SSS — exact value depends on timezone but format should match
        let regex = try! NSRegularExpression(pattern: #"^\d{2}:\d{2}:\d{2}\.\d{3}$"#)
        let range = NSRange(timestamp.startIndex..., in: timestamp)
        XCTAssertNotNil(regex.firstMatch(in: timestamp, range: range), "Timestamp '\(timestamp)' doesn't match HH:mm:ss.SSS format")
    }

    func testDefaultIsErrorFalse() {
        let entry = LogEntry(composeFileId: UUID(), message: "test")
        XCTAssertFalse(entry.isError)
    }

    func testIsErrorTrue() {
        let entry = LogEntry(composeFileId: UUID(), message: "error", isError: true)
        XCTAssertTrue(entry.isError)
    }
}

final class AppSettingsTests: XCTestCase {
    func testDefaultValues() {
        let settings = AppSettings.default
        XCTAssertEqual(settings.maxLogLines, 100_000)
        XCTAssertTrue(settings.composeFiles.isEmpty)
        XCTAssertEqual(settings.sidebarDisplayMode, .tree)
        // Docker path should be some valid default
        XCTAssertFalse(settings.dockerComposePath.isEmpty)
    }

    func testCodableRoundTrip() throws {
        let settings = AppSettings(
            maxLogLines: 500,
            dockerComposePath: "/custom/docker",
            composeFiles: [ComposeFile(name: "test", path: "/tmp/test.yml")],
            sidebarDisplayMode: .flat
        )
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        XCTAssertEqual(decoded.maxLogLines, 500)
        XCTAssertEqual(decoded.dockerComposePath, "/custom/docker")
        XCTAssertEqual(decoded.composeFiles.count, 1)
        XCTAssertEqual(decoded.sidebarDisplayMode, .flat)
    }
}

final class SidebarDisplayModeTests: XCTestCase {
    func testRawValues() {
        XCTAssertEqual(SidebarDisplayMode.flat.rawValue, "Flat List")
        XCTAssertEqual(SidebarDisplayMode.tree.rawValue, "Hierarchical Tree")
    }

    func testAllCases() {
        XCTAssertEqual(SidebarDisplayMode.allCases.count, 2)
    }
}
