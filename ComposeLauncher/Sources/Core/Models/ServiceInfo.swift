import Foundation

/// Represents a port publisher from docker compose ps JSON output
public struct PortPublisher: Codable, Hashable, Identifiable {
    public var id: String {
        "\(URL):\(PublishedPort)->\(TargetPort)/\(`Protocol`)"
    }

    public let URL: String
    public let TargetPort: Int
    public let PublishedPort: Int
    public let `Protocol`: String

    public init(URL: String, TargetPort: Int, PublishedPort: Int, Protocol proto: String) {
        self.URL = URL
        self.TargetPort = TargetPort
        self.PublishedPort = PublishedPort
        self.Protocol = proto
    }
}

/// Full service info from `docker compose ps --format json`.
/// Uses custom decoding to handle missing/null fields across Docker Compose versions.
public struct ServiceInfo: Codable, Hashable, Identifiable {
    public var id: String {
        let owner = composeFileId?.uuidString ?? "unknown"
        let container = !Name.isEmpty ? Name : Service
        let portSig = Publishers.map { "\($0.PublishedPort)" }.joined(separator: ",")
        return "\(owner)-\(container)-\(portSig)"
    }

    public let Service: String
    public let State: String
    public let Status: String
    public let Name: String
    public let Ports: String
    public let Publishers: [PortPublisher]

    // Added after parsing to track which compose file this belongs to
    public var composeFileId: UUID?
    public var composeFilePath: String?
    public var composeFileDisplayName: String?

    enum CodingKeys: String, CodingKey {
        case Service, State, Status, Name, Ports, Publishers
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        Service = try container.decode(String.self, forKey: .Service)
        State = try container.decodeIfPresent(String.self, forKey: .State) ?? ""
        Status = try container.decodeIfPresent(String.self, forKey: .Status) ?? ""
        Name = try container.decodeIfPresent(String.self, forKey: .Name) ?? ""
        Ports = try container.decodeIfPresent(String.self, forKey: .Ports) ?? ""
        Publishers = try container.decodeIfPresent([PortPublisher].self, forKey: .Publishers) ?? []
        composeFileId = nil
        composeFilePath = nil
        composeFileDisplayName = nil
    }

    public init(
        Service: String,
        State: String,
        Status: String = "",
        Name: String = "",
        Ports: String = "",
        Publishers: [PortPublisher] = [],
        composeFileId: UUID? = nil,
        composeFilePath: String? = nil,
        composeFileDisplayName: String? = nil
    ) {
        self.Service = Service
        self.State = State
        self.Status = Status
        self.Name = Name
        self.Ports = Ports
        self.Publishers = Publishers
        self.composeFileId = composeFileId
        self.composeFilePath = composeFilePath
        self.composeFileDisplayName = composeFileDisplayName
    }
}
