import SwiftUI

struct EditorView: View {
    let file: ComposeFile
    @ObservedObject var settingsManager = SettingsManager.shared
    @State private var content: String = ""
    @State private var originalContent: String = ""
    @State private var envContent: String = ""
    @State private var originalEnvContent: String = ""
    @State private var isLoading = true
    @State private var hasChanges = false
    @State private var hasEnvChanges = false
    @State private var showingSaveAlert = false
    @State private var showingEnvFilePicker = false
    @State private var errorMessage: String?
    @State private var isEditingEnvFile = false
    
    /// The currently effective file for this compose file (from settings)
    private var currentFile: ComposeFile {
        settingsManager.settings.composeFiles.first(where: { $0.id == file.id }) ?? file
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentFile.displayName)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(currentFile.path)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                if isEditingEnvFile ? hasEnvChanges : hasChanges {
                    Text("Modified")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(4)
                }
                
                Group {
                    Button(action: reloadContent) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                    }
                    .help("Reload from disk")
                    
                    Button(action: openInExternalEditor) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12))
                    }
                    .help("Open in external editor")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: isEditingEnvFile ? saveEnvContent : saveContent) {
                    Text("Save")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isEditingEnvFile ? !hasEnvChanges : !hasChanges)
                .keyboardShortcut("s", modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
            
            // Env File Bar
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                if let envPath = currentFile.envFilePath, !envPath.isEmpty {
                    // Has env file attached
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text(URL(fileURLWithPath: envPath).lastPathComponent)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    
                    Text(envPath)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    // Edit env file toggle
                    Button(action: {
                        if isEditingEnvFile {
                            isEditingEnvFile = false
                        } else {
                            loadEnvContent()
                            isEditingEnvFile = true
                        }
                    }) {
                        Text(isEditingEnvFile ? "Edit Compose" : "Edit .env")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .help(isEditingEnvFile ? "Switch back to editing the compose file" : "Edit the .env file contents")
                    
                    // Replace env file
                    Button(action: { showingEnvFilePicker = true }) {
                        Image(systemName: "folder")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .help("Replace .env file")
                    
                    // Remove env file
                    Button(action: removeEnvFile) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .help("Remove .env file association")
                } else {
                    // No env file attached
                    Text("No .env file")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { showingEnvFilePicker = true }) {
                        Label("Attach .env", systemImage: "plus")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .help("Attach an environment file (.env)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))
            
            Divider()
            
            // Editor
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        loadContent()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                Spacer()
            } else {
                if isEditingEnvFile {
                    CodeEditor(text: $envContent)
                        .onChange(of: envContent) { _, newValue in
                            hasEnvChanges = newValue != originalEnvContent
                        }
                } else {
                    CodeEditor(text: $content)
                        .onChange(of: content) { _, newValue in
                            hasChanges = newValue != originalContent
                        }
                }
            }
        }
        .onAppear {
            loadContent()
        }
        .onChange(of: file.id) { _, _ in
            isEditingEnvFile = false
            loadContent()
        }
        .fileImporter(
            isPresented: $showingEnvFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    var updatedFile = currentFile
                    updatedFile.envFilePath = url.path
                    settingsManager.updateComposeFile(updatedFile)
                }
            case .failure(let error):
                print("Failed to select .env file: \(error)")
            }
        }
        .alert("Unsaved Changes", isPresented: $showingSaveAlert) {
            Button("Save") { saveContent() }
            Button("Discard", role: .destructive) { reloadContent() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. What would you like to do?")
        }
    }
    
    private func loadContent() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileContent = try String(contentsOfFile: file.path, encoding: .utf8)
                DispatchQueue.main.async {
                    self.content = fileContent
                    self.originalContent = fileContent
                    self.hasChanges = false
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load file: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadEnvContent() {
        guard let envPath = currentFile.envFilePath else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileContent = try String(contentsOfFile: envPath, encoding: .utf8)
                DispatchQueue.main.async {
                    self.envContent = fileContent
                    self.originalEnvContent = fileContent
                    self.hasEnvChanges = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load .env file: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func reloadContent() {
        if (isEditingEnvFile ? hasEnvChanges : hasChanges) {
            showingSaveAlert = true
        } else {
            if isEditingEnvFile {
                loadEnvContent()
            } else {
                loadContent()
            }
        }
    }
    
    private func saveContent() {
        do {
            try content.write(toFile: file.path, atomically: true, encoding: .utf8)
            originalContent = content
            hasChanges = false
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
    
    private func saveEnvContent() {
        guard let envPath = currentFile.envFilePath else { return }
        do {
            try envContent.write(toFile: envPath, atomically: true, encoding: .utf8)
            originalEnvContent = envContent
            hasEnvChanges = false
        } catch {
            errorMessage = "Failed to save .env file: \(error.localizedDescription)"
        }
    }
    
    private func removeEnvFile() {
        isEditingEnvFile = false
        var updatedFile = currentFile
        updatedFile.envFilePath = nil
        settingsManager.updateComposeFile(updatedFile)
    }
    
    private func openInExternalEditor() {
        if isEditingEnvFile, let envPath = currentFile.envFilePath {
            NSWorkspace.shared.open(URL(fileURLWithPath: envPath))
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: file.path))
        }
    }
}

struct CodeEditor: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.textColor
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        
        // Line numbers and styling
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditor
        
        init(_ parent: CodeEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
