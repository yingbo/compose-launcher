import SwiftUI

public struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var composeManager = DockerComposeManager.shared
    @State private var selectedFile: ComposeFile?
    @State private var showingSettings = false
    @State private var selectedTab: DetailTab = .logs
    
    enum DetailTab: String, CaseIterable {
        case logs = "Logs"
        case editor = "Editor"
    }
    
    public init() {}

    public var body: some View {
        NavigationSplitView {
            SidebarView(
                settingsManager: settingsManager,
                composeManager: composeManager,
                selectedFile: $selectedFile
            )
        } detail: {
            if selectedFile != nil {
                VStack(spacing: 0) {
                    // Tab bar
                    HStack(spacing: 0) {
                        ForEach(DetailTab.allCases, id: \.self) { tab in
                            TabButton(
                                title: tab.rawValue,
                                icon: tab == .logs ? "doc.text" : "pencil",
                                isSelected: selectedTab == tab
                            ) {
                                selectedTab = tab
                            }
                            .accessibilityIdentifier("tab-\(tab.rawValue.lowercased())")
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .windowBackgroundColor))
                    
                    Divider()
                    
                    // Content
                    switch selectedTab {
                    case .logs:
                        LogPanelView(
                            composeManager: composeManager,
                            selectedFile: selectedFile
                        )
                    case .editor:
                        if let file = selectedFile {
                            EditorView(file: file)
                        }
                    }
                }
            } else {
                EmptyStateView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
                .help("Settings")
                .accessibilityIdentifier("settings-button")
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settingsManager: settingsManager)
        }
        .onAppear {
            composeManager.configure(
                maxLogLines: settingsManager.settings.maxLogLines,
                dockerPath: settingsManager.settings.dockerComposePath
            )
        }
        .onChange(of: settingsManager.settings.maxLogLines) { _, newValue in
            composeManager.configure(
                maxLogLines: newValue,
                dockerPath: settingsManager.settings.dockerComposePath
            )
        }
        .onChange(of: settingsManager.settings.dockerComposePath) { _, newValue in
            composeManager.configure(
                maxLogLines: settingsManager.settings.maxLogLines,
                dockerPath: newValue
            )
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Compose File Selected")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Add a Docker Compose file from the sidebar\nor select an existing one to view logs and edit.")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}


