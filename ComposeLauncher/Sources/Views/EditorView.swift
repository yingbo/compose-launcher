import SwiftUI

struct EditorView: View {
    let file: ComposeFile
    @ObservedObject var settingsManager = SettingsManager.shared
    @State private var content: String = ""
    @State private var originalContent: String = ""
    @State private var isLoading = true
    @State private var hasChanges = false
    @State private var showingSaveAlert = false
    @State private var showingEnvFilePicker = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(file.displayName)
                            .font(.system(size: 14, weight: .semibold))
                        
                        if let envPath = file.envFilePath {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.system(size: 8))
                                Text(URL(fileURLWithPath: envPath).lastPathComponent)
                                    .font(.system(size: 10))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(4)
                            .foregroundColor(.accentColor)
                        }
                    }
                    
                    Text(file.path)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                if hasChanges {
                    Text("Modified")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(4)
                }
                
                Group {
                    Button(action: { showingEnvFilePicker = true }) {
                        Label("Env File", systemImage: "gearshape")
                            .font(.system(size: 11))
                    }
                    .help("Select environment file (.env)")
                    
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
                
                Button(action: saveContent) {
                    Text("Save")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!hasChanges)
                .keyboardShortcut("s", modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
            
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
                CodeEditor(text: $content)
                    .onChange(of: content) { _, newValue in
                        hasChanges = newValue != originalContent
                    }
            }
        }
        .onAppear {
            loadContent()
        }
        .onChange(of: file.id) { _, _ in
            loadContent()
        }
        .fileImporter(
            isPresented: $showingEnvFilePicker,
            allowedContentTypes: [.item], // Allow all files since .env often has no extension or is treated as plain text
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // Start accessing security-scoped resource
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    var updatedFile = file
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
    
    private func reloadContent() {
        if hasChanges {
            showingSaveAlert = true
        } else {
            loadContent()
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
    
    private func openInExternalEditor() {
        NSWorkspace.shared.open(URL(fileURLWithPath: file.path))
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
