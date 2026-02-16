import Foundation
import Yams

@MainActor
public class SettingsManager: ObservableObject {
    @Published public var settings: AppSettings

    private let settingsURL: URL

    public static let shared = SettingsManager()

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ComposeLauncher", isDirectory: true)

        // Create app folder if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        self.settingsURL = appFolder.appendingPathComponent("settings.yaml")
        self.settings = AppSettings.default

        loadSettings()
    }

    public init(settingsURL: URL) {
        try? FileManager.default.createDirectory(
            at: settingsURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        self.settingsURL = settingsURL
        self.settings = AppSettings.default

        loadSettings()
    }

    public func loadSettings() {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            return
        }

        do {
            let yamlString = try String(contentsOf: settingsURL, encoding: .utf8)
            let decoder = YAMLDecoder()
            settings = try decoder.decode(AppSettings.self, from: yamlString)
        } catch is DecodingError {
            // Corrupt or incompatible YAML should fall back to defaults silently.
            // This avoids noisy logs during tests and for end users with bad settings files.
        } catch {
            print("Failed to load settings: \(error)")
        }
    }

    public func saveSettings() {
        do {
            let encoder = YAMLEncoder()
            let yamlString = try encoder.encode(settings)
            try yamlString.write(to: settingsURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }

    public func addComposeFile(_ file: ComposeFile) {
        settings.composeFiles.append(file)
        saveSettings()
    }

    public func removeComposeFile(_ file: ComposeFile) {
        settings.composeFiles.removeAll { $0.id == file.id }
        saveSettings()
    }

    public func updateComposeFile(_ file: ComposeFile) {
        if let index = settings.composeFiles.firstIndex(where: { $0.id == file.id }) {
            settings.composeFiles[index] = file
            saveSettings()
        }
    }

    public func updateMaxLogLines(_ lines: Int) {
        settings.maxLogLines = lines
        saveSettings()
    }

    public func updateDockerPath(_ path: String) {
        settings.dockerComposePath = path
        saveSettings()
    }

    public func updateSidebarDisplayMode(_ mode: SidebarDisplayMode) {
        settings.sidebarDisplayMode = mode
        saveSettings()
    }
}
