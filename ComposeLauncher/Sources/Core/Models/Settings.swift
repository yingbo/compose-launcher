import Foundation

public enum SidebarDisplayMode: String, Codable, CaseIterable {
    case flat = "Flat List"
    case tree = "Hierarchical Tree"
}

public struct AppSettings: Codable {
    public var maxLogLines: Int
    public var dockerComposePath: String
    public var composeFiles: [ComposeFile]
    public var sidebarDisplayMode: SidebarDisplayMode

    public init(maxLogLines: Int = 100_000,
         dockerComposePath: String = "/usr/local/bin/docker",
         composeFiles: [ComposeFile] = [],
         sidebarDisplayMode: SidebarDisplayMode = .tree) {
        let defaultDockerPath: String
        #if arch(arm64)
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/docker") {
            defaultDockerPath = "/opt/homebrew/bin/docker"
        } else if FileManager.default.fileExists(atPath: "/usr/local/bin/docker") {
            defaultDockerPath = "/usr/local/bin/docker"
        } else {
            defaultDockerPath = "/usr/local/bin/docker" // Fallback
        }
        #else
        defaultDockerPath = "/usr/local/bin/docker"
        #endif

        self.maxLogLines = maxLogLines
        self.dockerComposePath = dockerComposePath == "/usr/local/bin/docker" ? defaultDockerPath : dockerComposePath
        self.composeFiles = composeFiles
        self.sidebarDisplayMode = sidebarDisplayMode
    }

    public static let `default` = AppSettings()
}
