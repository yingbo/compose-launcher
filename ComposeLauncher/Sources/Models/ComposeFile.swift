import Foundation

struct ComposeFile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: String
    var envFilePath: String?
    var isRunning: Bool
    var addedDate: Date
    
    init(id: UUID = UUID(), name: String, path: String, envFilePath: String? = nil, isRunning: Bool = false, addedDate: Date = Date()) {
        self.id = id
        self.name = name
        self.path = path
        self.envFilePath = envFilePath
        self.isRunning = isRunning
        self.addedDate = addedDate
    }
    
    var displayName: String {
        if name.isEmpty {
            return URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
        }
        return name
    }
}
