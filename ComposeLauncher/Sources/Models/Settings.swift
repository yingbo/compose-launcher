import Foundation

struct AppSettings: Codable {
    var maxLogLines: Int
    var dockerComposePath: String
    var composeFiles: [ComposeFile]
    
    init(maxLogLines: Int = 100_000, dockerComposePath: String = "/usr/local/bin/docker", composeFiles: [ComposeFile] = []) {
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
    }
    
    static let `default` = AppSettings()
}
