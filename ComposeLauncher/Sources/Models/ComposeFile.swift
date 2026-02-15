import Foundation

struct ComposeFile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: String
    var envFilePath: String?
    var isRunning: Bool
    var addedDate: Date
    var customName: String?

    init(id: UUID = UUID(), name: String, path: String, envFilePath: String? = nil, isRunning: Bool = false, addedDate: Date = Date(), customName: String? = nil) {
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

    /// Smart display name:
    /// - If user set a custom name, use that
    /// - If filename is standard (docker-compose.yml, etc.), show just the parent folder
    /// - Otherwise, show parent_folder/filename
    var displayName: String {
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
