import Foundation

struct ComposeFile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: String
    var isRunning: Bool
    var addedDate: Date
    
    init(id: UUID = UUID(), name: String, path: String, isRunning: Bool = false, addedDate: Date = Date()) {
        self.id = id
        self.name = name
        self.path = path
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
