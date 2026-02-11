import SwiftUI

@main
struct ComposeLauncherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("Compose") {
                Button("Add Compose File...") {
                    NotificationCenter.default.post(name: .addComposeFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
                
                Button("Start Selected") {
                    NotificationCenter.default.post(name: .startCompose, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Stop Selected") {
                    NotificationCenter.default.post(name: .stopCompose, object: nil)
                }
                .keyboardShortcut(".", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView(settingsManager: SettingsManager.shared)
        }
    }
}

extension Notification.Name {
    static let addComposeFile = Notification.Name("addComposeFile")
    static let startCompose = Notification.Name("startCompose")
    static let stopCompose = Notification.Name("stopCompose")
}
