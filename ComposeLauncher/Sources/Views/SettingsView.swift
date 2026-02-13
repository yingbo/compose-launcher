import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var maxLogLines: String = ""
    @State private var dockerPath: String = ""
    @State private var sidebarDisplayMode: SidebarDisplayMode = .flat
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Docker Settings
                    SettingsSection(title: "Docker", icon: "shippingbox") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Docker executable path")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("Path to docker", text: $dockerPath)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 13, design: .monospaced))
                                
                                Button("Browse") {
                                    browseForDocker()
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Text("Usually /usr/local/bin/docker or /opt/homebrew/bin/docker")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    // Appearance Settings
                    SettingsSection(title: "Appearance", icon: "paintbrush") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sidebar Display Mode")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Picker("", selection: $sidebarDisplayMode) {
                                ForEach(SidebarDisplayMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            
                            Text("Choose how your compose files are organized in the sidebar.")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    // Logging Settings
                    SettingsSection(title: "Logging", icon: "doc.text") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Maximum log lines to keep")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("100000", text: $maxLogLines)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 120)
                                
                                Text("lines")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Older logs will be automatically removed when this limit is exceeded")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    // Storage Info
                    SettingsSection(title: "Storage", icon: "folder") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Settings file location:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Reveal in Finder") {
                                    revealSettingsFile()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            Text(settingsFilePath)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(20)
        }
        .frame(width: 500, height: 450)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private var settingsFilePath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("ComposeLauncher/settings.yaml").path
    }
    
    private func loadCurrentSettings() {
        maxLogLines = String(settingsManager.settings.maxLogLines)
        dockerPath = settingsManager.settings.dockerComposePath
        sidebarDisplayMode = settingsManager.settings.sidebarDisplayMode
    }
    
    private func saveSettings() {
        if let lines = Int(maxLogLines), lines > 0 {
            settingsManager.updateMaxLogLines(lines)
        }
        settingsManager.updateDockerPath(dockerPath)
        settingsManager.updateSidebarDisplayMode(sidebarDisplayMode)
    }
    
    private func resetToDefaults() {
        let defaults = AppSettings.default
        maxLogLines = String(defaults.maxLogLines)
        dockerPath = defaults.dockerComposePath
        sidebarDisplayMode = defaults.sidebarDisplayMode
    }
    
    private func browseForDocker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/usr/local/bin")
        
        if panel.runModal() == .OK, let url = panel.url {
            dockerPath = url.path
        }
    }
    
    private func revealSettingsFile() {
        let url = URL(fileURLWithPath: settingsFilePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            
            content
                .padding(.leading, 22)
        }
        .padding(16)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(10)
    }
}
