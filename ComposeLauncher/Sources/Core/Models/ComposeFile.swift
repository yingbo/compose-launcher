import Foundation

public struct ComposeFile: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var path: String
    public var envFilePath: String?
    public var isRunning: Bool
    public var addedDate: Date

    public init(id: UUID = UUID(), name: String, path: String, envFilePath: String? = nil, isRunning: Bool = false, addedDate: Date = Date()) {
        self.id = id
        self.name = name
        self.path = path
        self.envFilePath = envFilePath
        self.isRunning = isRunning
        self.addedDate = addedDate
    }

    public var displayName: String {
        if name.isEmpty {
            return URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
        }
        return name
    }
}
