import Foundation

struct LogEntry: Identifiable, Hashable {
    let id: UUID
    let timestamp: Date
    let composeFileId: UUID
    let message: String
    let isError: Bool
    
    init(id: UUID = UUID(), timestamp: Date = Date(), composeFileId: UUID, message: String, isError: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.composeFileId = composeFileId
        self.message = message
        self.isError = isError
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}
