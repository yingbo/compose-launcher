import Foundation

public struct ComposeFile: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var path: String
    public var envFilePath: String?
    public var isRunning: Bool
    public var addedDate: Date
    public var customName: String?

    public init(id: UUID = UUID(), name: String, path: String, envFilePath: String? = nil, isRunning: Bool = false, addedDate: Date = Date(), customName: String? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.envFilePath = envFilePath
        self.isRunning = isRunning
        self.addedDate = addedDate
        self.customName = customName
    }

    /// Standard compose filenames that don't need to be shown in the display name
    private static let standardComposeFilenames: Set<String> = [
        "docker-compose.yml",
        "docker-compose.yaml",
        "compose.yml",
        "compose.yaml"
    ]

    public var displayName: String {
        if let custom = customName, !custom.isEmpty {
            return custom
        }
        let url = URL(fileURLWithPath: path)
        let filename = url.lastPathComponent
        let parentFolder = url.deletingLastPathComponent().lastPathComponent

        if Self.standardComposeFilenames.contains(filename.lowercased()) {
            return parentFolder
        }
        return "\(parentFolder)/\(filename)"
    }
}
