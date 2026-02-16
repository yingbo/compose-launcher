import Foundation

public struct LogEntry: Identifiable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let composeFileId: UUID
    public let message: String
    public let isError: Bool

    public init(id: UUID = UUID(), timestamp: Date = Date(), composeFileId: UUID, message: String, isError: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.composeFileId = composeFileId
        self.message = message
        self.isError = isError
    }

    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}
