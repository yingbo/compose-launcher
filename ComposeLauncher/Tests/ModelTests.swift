import XCTest
@testable import ComposeLauncherCore

final class ComposeFileTests: XCTestCase {
    func testInitDefaults() {
        let file = ComposeFile(name: "test", path: "/tmp/docker-compose.yml")
        XCTAssertFalse(file.isRunning)
        XCTAssertNil(file.envFilePath)
        XCTAssertFalse(file.id.uuidString.isEmpty)
    }

    func testDisplayNameUsesCustomNameWhenPresent() {
        let file = ComposeFile(
            name: "",
            path: "/tmp/docker-compose.yml",
            customName: "my-project"
        )
        XCTAssertEqual(file.displayName, "my-project")
    }

    func testDisplayNameForStandardComposeFilenameUsesFolder() {
        let file = ComposeFile(name: "", path: "/Users/test/my-project/docker-compose.yml")
        XCTAssertEqual(file.displayName, "my-project")
    }

    func testDisplayNameForNonStandardComposeFilenameUsesFolderAndFilename() {
        let file = ComposeFile(name: "", path: "/Users/test/my-project/docker-compose.prod.yml")
        XCTAssertEqual(file.displayName, "my-project/docker-compose.prod.yml")
    }

    func testCodableRoundTrip() throws {
        let original = ComposeFile(
            name: "test-project",
            path: "/tmp/compose.yml",
            envFilePath: "/tmp/.env",
            customName: "custom-test-project"
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

final class ServiceInfoTests: XCTestCase {
    func testDecodingFromDockerJSON() throws {
        let json = """
        {
            "Service": "web",
            "State": "running",
            "Status": "Up 2 hours",
            "Name": "myproject-web-1",
            "Ports": "0.0.0.0:8080->80/tcp",
            "Publishers": [
                {"URL": "0.0.0.0", "TargetPort": 80, "PublishedPort": 8080, "Protocol": "tcp"}
            ]
        }
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(ServiceInfo.self, from: json)
        XCTAssertEqual(info.Service, "web")
        XCTAssertEqual(info.State, "running")
        XCTAssertEqual(info.Status, "Up 2 hours")
        XCTAssertEqual(info.Name, "myproject-web-1")
        XCTAssertEqual(info.Publishers.count, 1)
        XCTAssertEqual(info.Publishers[0].PublishedPort, 8080)
        XCTAssertEqual(info.Publishers[0].TargetPort, 80)
        XCTAssertEqual(info.Publishers[0].URL, "0.0.0.0")
        XCTAssertEqual(info.Publishers[0].Protocol, "tcp")
    }

    func testDecodingWithEmptyPublishers() throws {
        let json = """
        {
            "Service": "redis",
            "State": "running",
            "Status": "Up 5 minutes",
            "Name": "myproject-redis-1",
            "Ports": "",
            "Publishers": []
        }
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(ServiceInfo.self, from: json)
        XCTAssertEqual(info.Service, "redis")
        XCTAssertTrue(info.Publishers.isEmpty)
    }

    func testDecodingMultiplePublishers() throws {
        let json = """
        {
            "Service": "nginx",
            "State": "running",
            "Status": "Up 1 hour",
            "Name": "myproject-nginx-1",
            "Ports": "0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp",
            "Publishers": [
                {"URL": "0.0.0.0", "TargetPort": 80, "PublishedPort": 80, "Protocol": "tcp"},
                {"URL": "0.0.0.0", "TargetPort": 443, "PublishedPort": 443, "Protocol": "tcp"}
            ]
        }
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(ServiceInfo.self, from: json)
        XCTAssertEqual(info.Publishers.count, 2)
        XCTAssertEqual(info.Publishers[0].PublishedPort, 80)
        XCTAssertEqual(info.Publishers[1].PublishedPort, 443)
    }

    func testDecodingWithMissingOptionalFields() throws {
        // Docker Compose versions may omit fields like Status, Ports, Publishers
        let json = """
        {
            "Service": "web"
        }
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(ServiceInfo.self, from: json)
        XCTAssertEqual(info.Service, "web")
        XCTAssertEqual(info.State, "")
        XCTAssertEqual(info.Status, "")
        XCTAssertEqual(info.Name, "")
        XCTAssertEqual(info.Ports, "")
        XCTAssertTrue(info.Publishers.isEmpty)
    }

    func testDecodingWithPartialFields() throws {
        let json = """
        {
            "Service": "api",
            "State": "running",
            "Name": "proj-api-1"
        }
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(ServiceInfo.self, from: json)
        XCTAssertEqual(info.Service, "api")
        XCTAssertEqual(info.State, "running")
        XCTAssertEqual(info.Name, "proj-api-1")
        XCTAssertEqual(info.Ports, "")
        XCTAssertTrue(info.Publishers.isEmpty)
    }

    func testNonCodedPropertiesAreNilAfterDecoding() throws {
        let json = """
        {
            "Service": "web",
            "State": "running",
            "Status": "",
            "Name": "web-1",
            "Ports": "",
            "Publishers": []
        }
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(ServiceInfo.self, from: json)
        XCTAssertNil(info.composeFileId)
        XCTAssertNil(info.composeFilePath)
        XCTAssertNil(info.composeFileDisplayName)
    }

    func testPortConflictDetection() {
        // Same address, port, and protocol across different services = conflict
        let s1 = ServiceInfo(
            Service: "web", State: "running", Name: "p1-web-1",
            Publishers: [PortPublisher(URL: "0.0.0.0", TargetPort: 80, PublishedPort: 8080, Protocol: "tcp")]
        )
        let s2 = ServiceInfo(
            Service: "api", State: "running", Name: "p2-api-1",
            Publishers: [PortPublisher(URL: "0.0.0.0", TargetPort: 3000, PublishedPort: 8080, Protocol: "tcp")]
        )
        let s3 = ServiceInfo(
            Service: "db", State: "running", Name: "p1-db-1",
            Publishers: [PortPublisher(URL: "0.0.0.0", TargetPort: 5432, PublishedPort: 5432, Protocol: "tcp")]
        )

        let conflicts = ServicesView.computeConflicts(from: [s1, s2, s3])
        XCTAssertEqual(conflicts.count, 1)
        XCTAssertTrue(conflicts.contains(ServicesView.PortBinding(url: "0.0.0.0", port: 8080, proto: "tcp")))
        XCTAssertFalse(conflicts.contains(ServicesView.PortBinding(url: "0.0.0.0", port: 5432, proto: "tcp")))
    }

    func testPortConflictDifferentAddressNoConflict() {
        // Same port but different bind addresses = no conflict
        let s1 = ServiceInfo(
            Service: "web", State: "running", Name: "p1-web-1",
            Publishers: [PortPublisher(URL: "127.0.0.1", TargetPort: 80, PublishedPort: 8080, Protocol: "tcp")]
        )
        let s2 = ServiceInfo(
            Service: "api", State: "running", Name: "p2-api-1",
            Publishers: [PortPublisher(URL: "0.0.0.0", TargetPort: 3000, PublishedPort: 8080, Protocol: "tcp")]
        )

        let conflicts = ServicesView.computeConflicts(from: [s1, s2])
        XCTAssertTrue(conflicts.isEmpty)
    }

    func testDecodingWithPortsButNoPublishers() throws {
        // Some Docker Compose versions provide Ports text but omit Publishers
        let json = """
        {
            "Service": "web",
            "State": "running",
            "Name": "proj-web-1",
            "Ports": "0.0.0.0:8080->80/tcp"
        }
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(ServiceInfo.self, from: json)
        XCTAssertEqual(info.Service, "web")
        XCTAssertEqual(info.Ports, "0.0.0.0:8080->80/tcp")
        XCTAssertTrue(info.Publishers.isEmpty, "Publishers should be empty when omitted from JSON")
    }

    func testParsePortBindingsSimple() {
        let bindings = ServicesView.parsePortBindings(from: "0.0.0.0:8080->80/tcp")
        XCTAssertEqual(bindings.count, 1)
        XCTAssertEqual(bindings[0].url, "0.0.0.0")
        XCTAssertEqual(bindings[0].port, 8080)
        XCTAssertEqual(bindings[0].proto, "tcp")
    }

    func testParsePortBindingsMultiple() {
        let bindings = ServicesView.parsePortBindings(from: "0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp")
        XCTAssertEqual(bindings.count, 2)
        XCTAssertEqual(bindings[0].port, 80)
        XCTAssertEqual(bindings[1].port, 443)
    }

    func testParsePortBindingsIPv6() {
        let bindings = ServicesView.parsePortBindings(from: ":::8080->80/tcp")
        XCTAssertEqual(bindings.count, 1)
        XCTAssertEqual(bindings[0].url, "::")
        XCTAssertEqual(bindings[0].port, 8080)
    }

    func testParsePortBindingsSkipsExposedOnly() {
        // "80/tcp" has no host binding — should be skipped
        let bindings = ServicesView.parsePortBindings(from: "80/tcp")
        XCTAssertTrue(bindings.isEmpty)
    }

    func testConflictDetectionWithPortsOnlyServices() {
        // Two services with same host binding via Ports text (no Publishers)
        let s1 = ServiceInfo(
            Service: "web", State: "running", Name: "p1-web-1",
            Ports: "0.0.0.0:8080->80/tcp"
        )
        let s2 = ServiceInfo(
            Service: "api", State: "running", Name: "p2-api-1",
            Ports: "0.0.0.0:8080->3000/tcp"
        )
        let conflicts = ServicesView.computeConflicts(from: [s1, s2])
        XCTAssertEqual(conflicts.count, 1)
        XCTAssertTrue(conflicts.contains(ServicesView.PortBinding(url: "0.0.0.0", port: 8080, proto: "tcp")))
    }

    // MARK: - Deduplication (issue #21: duplicate services from shared Docker project)

    func testDeduplicateServicesRemovesSameContainerFromMultipleFiles() {
        // Scenario from the bug: two compose files in the same directory both report
        // the same running container (e.g. "sample-compose-mongodb-1").
        let fileId1 = UUID()
        let fileId2 = UUID()
        let s1 = ServiceInfo(
            Service: "mongodb", State: "running", Name: "sample-compose-mongodb-1",
            Publishers: [
                PortPublisher(URL: "0.0.0.0", TargetPort: 27017, PublishedPort: 27017, Protocol: "tcp"),
                PortPublisher(URL: "::", TargetPort: 27017, PublishedPort: 27017, Protocol: "tcp")
            ],
            composeFileId: fileId1, composeFileDisplayName: "sample-compose/langfuse"
        )
        let s2 = ServiceInfo(
            Service: "mongodb", State: "running", Name: "sample-compose-mongodb-1",
            Publishers: [
                PortPublisher(URL: "0.0.0.0", TargetPort: 27017, PublishedPort: 27017, Protocol: "tcp"),
                PortPublisher(URL: "::", TargetPort: 27017, PublishedPort: 27017, Protocol: "tcp")
            ],
            composeFileId: fileId2, composeFileDisplayName: "sample-compose/mongo"
        )

        let unique = ServicesView.deduplicateServices([s1, s2])
        XCTAssertEqual(unique.count, 1, "Same container should appear only once")
        XCTAssertEqual(unique[0].composeFileId, fileId1, "First occurrence should be kept")
    }

    func testDeduplicateServicesKeepsDifferentContainers() {
        let s1 = ServiceInfo(Service: "web", State: "running", Name: "proj-web-1")
        let s2 = ServiceInfo(Service: "db", State: "running", Name: "proj-db-1")
        let unique = ServicesView.deduplicateServices([s1, s2])
        XCTAssertEqual(unique.count, 2)
    }

    func testDeduplicateServicesKeepsServicesWithEmptyName() {
        // Services with empty Name (old Docker versions) should not be deduplicated
        let s1 = ServiceInfo(Service: "web", State: "running", Name: "")
        let s2 = ServiceInfo(Service: "api", State: "running", Name: "")
        let unique = ServicesView.deduplicateServices([s1, s2])
        XCTAssertEqual(unique.count, 2)
    }

    func testNoFalseConflictFromDuplicateContainer() {
        // The exact bug scenario: same container returned twice (from two compose files)
        // should NOT produce a port conflict after deduplication.
        let s1 = ServiceInfo(
            Service: "mongodb", State: "running", Name: "sample-compose-mongodb-1",
            Publishers: [
                PortPublisher(URL: "0.0.0.0", TargetPort: 27017, PublishedPort: 27017, Protocol: "tcp"),
                PortPublisher(URL: "::", TargetPort: 27017, PublishedPort: 27017, Protocol: "tcp")
            ],
            composeFileId: UUID()
        )
        let s2 = ServiceInfo(
            Service: "mongodb", State: "running", Name: "sample-compose-mongodb-1",
            Publishers: [
                PortPublisher(URL: "0.0.0.0", TargetPort: 27017, PublishedPort: 27017, Protocol: "tcp"),
                PortPublisher(URL: "::", TargetPort: 27017, PublishedPort: 27017, Protocol: "tcp")
            ],
            composeFileId: UUID()
        )

        // Without deduplication, the old code would report 2 conflicts
        let unique = ServicesView.deduplicateServices([s1, s2])
        let conflicts = ServicesView.computeConflicts(from: unique)
        XCTAssertTrue(conflicts.isEmpty, "Single container should have no port conflicts")
    }

    func testNoFalseConflictFromDuplicatePublishersWithinService() {
        // Some Docker Compose versions emit duplicate entries in Publishers array
        let service = ServiceInfo(
            Service: "mongodb", State: "running", Name: "proj-mongodb-1",
            Publishers: [
                PortPublisher(URL: "0.0.0.0", TargetPort: 27017, PublishedPort: 27017, Protocol: "tcp"),
                PortPublisher(URL: "0.0.0.0", TargetPort: 27017, PublishedPort: 27017, Protocol: "tcp"),
                PortPublisher(URL: "::", TargetPort: 27017, PublishedPort: 27017, Protocol: "tcp"),
                PortPublisher(URL: "::", TargetPort: 27017, PublishedPort: 27017, Protocol: "tcp")
            ]
        )

        let conflicts = ServicesView.computeConflicts(from: [service])
        XCTAssertTrue(conflicts.isEmpty,
            "Duplicate publishers within a single service should not trigger false conflicts")
    }

    func testRealConflictStillDetectedAfterDeduplication() {
        // Two genuinely different services binding the same port = real conflict
        let s1 = ServiceInfo(
            Service: "web", State: "running", Name: "proj-web-1",
            Publishers: [PortPublisher(URL: "0.0.0.0", TargetPort: 80, PublishedPort: 8080, Protocol: "tcp")]
        )
        let s2 = ServiceInfo(
            Service: "api", State: "running", Name: "proj-api-1",
            Publishers: [PortPublisher(URL: "0.0.0.0", TargetPort: 3000, PublishedPort: 8080, Protocol: "tcp")]
        )

        let unique = ServicesView.deduplicateServices([s1, s2])
        let conflicts = ServicesView.computeConflicts(from: unique)
        XCTAssertEqual(conflicts.count, 1)
        XCTAssertTrue(conflicts.contains(ServicesView.PortBinding(url: "0.0.0.0", port: 8080, proto: "tcp")))
    }

    func testIdUniquenessWithEmptyNames() {
        // Two services in the same compose file with empty Name should still get distinct IDs
        let fileId = UUID()
        let s1 = ServiceInfo(
            Service: "web", State: "running", Name: "",
            Publishers: [PortPublisher(URL: "0.0.0.0", TargetPort: 80, PublishedPort: 8080, Protocol: "tcp")],
            composeFileId: fileId
        )
        let s2 = ServiceInfo(
            Service: "web", State: "running", Name: "",
            Publishers: [PortPublisher(URL: "0.0.0.0", TargetPort: 3000, PublishedPort: 3000, Protocol: "tcp")],
            composeFileId: fileId
        )
        XCTAssertNotEqual(s1.id, s2.id, "Services with same name but different ports should have distinct IDs")
    }

    func testInitWithAllParameters() {
        let fileId = UUID()
        let info = ServiceInfo(
            Service: "web",
            State: "running",
            Status: "Up 2 hours",
            Name: "myproject-web-1",
            Ports: "0.0.0.0:8080->80/tcp",
            Publishers: [PortPublisher(URL: "0.0.0.0", TargetPort: 80, PublishedPort: 8080, Protocol: "tcp")],
            composeFileId: fileId,
            composeFilePath: "/tmp/compose.yml",
            composeFileDisplayName: "my-project"
        )
        XCTAssertEqual(info.composeFileId, fileId)
        XCTAssertEqual(info.composeFilePath, "/tmp/compose.yml")
        XCTAssertEqual(info.composeFileDisplayName, "my-project")
    }
}

final class PortPublisherTests: XCTestCase {
    func testId() {
        let pub = PortPublisher(URL: "0.0.0.0", TargetPort: 80, PublishedPort: 8080, Protocol: "tcp")
        XCTAssertEqual(pub.id, "0.0.0.0:8080->80/tcp")
    }

    func testHashable() {
        let pub1 = PortPublisher(URL: "0.0.0.0", TargetPort: 80, PublishedPort: 8080, Protocol: "tcp")
        let pub2 = PortPublisher(URL: "0.0.0.0", TargetPort: 443, PublishedPort: 443, Protocol: "tcp")
        let pub3 = PortPublisher(URL: "0.0.0.0", TargetPort: 80, PublishedPort: 8080, Protocol: "tcp")
        let set: Set<PortPublisher> = [pub1, pub2, pub3]
        XCTAssertEqual(set.count, 2)
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
