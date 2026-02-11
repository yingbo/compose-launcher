import Foundation
import Yams

@MainActor
class SettingsManager: ObservableObject {
    @Published var settings: AppSettings
    
    private let settingsURL: URL
    
    static let shared = SettingsManager()
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ComposeLauncher", isDirectory: true)
        
        // Create app folder if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        self.settingsURL = appFolder.appendingPathComponent("settings.yaml")
        self.settings = AppSettings.default
        
        loadSettings()
    }
    
    func loadSettings() {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            return
        }
        
        do {
            let yamlString = try String(contentsOf: settingsURL, encoding: .utf8)
            let decoder = YAMLDecoder()
            settings = try decoder.decode(AppSettings.self, from: yamlString)
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
    
    func saveSettings() {
        do {
            let encoder = YAMLEncoder()
            let yamlString = try encoder.encode(settings)
            try yamlString.write(to: settingsURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    func addComposeFile(_ file: ComposeFile) {
        settings.composeFiles.append(file)
        saveSettings()
    }
    
    func removeComposeFile(_ file: ComposeFile) {
        settings.composeFiles.removeAll { $0.id == file.id }
        saveSettings()
    }
    
    func updateComposeFile(_ file: ComposeFile) {
        if let index = settings.composeFiles.firstIndex(where: { $0.id == file.id }) {
            settings.composeFiles[index] = file
            saveSettings()
        }
    }
    
    func updateMaxLogLines(_ lines: Int) {
        settings.maxLogLines = lines
        saveSettings()
    }
    
    func updateDockerPath(_ path: String) {
        settings.dockerComposePath = path
        saveSettings()
    }
}
