import SwiftUI
import AppKit

struct LogPanelView: View {
    @ObservedObject var composeManager: DockerComposeManager
    let selectedFile: ComposeFile?
    @State private var autoScroll = true
    @State private var searchText = ""
    @State private var showAllLogs = false
    
    private var filteredLogs: [LogEntry] {
        var logs = composeManager.logs
        
        // Filter by selected file unless showing all
        if !showAllLogs, let file = selectedFile {
            logs = logs.filter { $0.composeFileId == file.id }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            logs = logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }
        
        return logs
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                Text("Logs")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(6)
                .frame(width: 180)
                
                Toggle(isOn: $showAllLogs) {
                    Text("All")
                        .font(.system(size: 11))
                }
                .toggleStyle(.checkbox)
                .help("Show logs from all compose files")
                
                Toggle(isOn: $autoScroll) {
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: 11))
                }
                .toggleStyle(.checkbox)
                .help("Auto-scroll to bottom")
                
                Button(action: clearLogs) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear logs")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Log content - using NSTextView for proper text selection and copy
            LogTextView(logs: filteredLogs, autoScroll: autoScroll)
            
            // Status bar
            HStack {
                Text("\(filteredLogs.count) lines")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let file = selectedFile {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(composeManager.isRunning(file) ? Color.green : Color.gray)
                            .frame(width: 6, height: 6)
                        Text(file.displayName)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }
    
    private func clearLogs() {
        if showAllLogs {
            composeManager.clearLogs()
        } else {
            composeManager.clearLogs(for: selectedFile?.id)
        }
    }
}

// MARK: - LogTextView (NSViewRepresentable for selectable/copyable logs)

struct LogTextView: NSViewRepresentable {
    let logs: [LogEntry]
    let autoScroll: Bool
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // Configure as read-only log viewer
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.textColor
        textView.isRichText = true
        textView.allowsUndo = false
        
        // Disable automatic text features
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        // Styling
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        // Store coordinator reference for scroll tracking
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Build attributed string from logs
        let attributedString = buildAttributedString(from: logs)
        
        // Check if content has changed
        let currentLength = textView.textStorage?.length ?? 0
        let newLength = attributedString.length
        
        if currentLength != newLength || context.coordinator.lastLogCount != logs.count {
            // Save selection if any
            let selectedRanges = textView.selectedRanges
            
            // Update content
            textView.textStorage?.setAttributedString(attributedString)
            
            // Restore selection if still valid
            if !selectedRanges.isEmpty {
                let validRanges = selectedRanges.compactMap { rangeValue -> NSValue? in
                    let range = rangeValue.rangeValue
                    if range.location + range.length <= newLength {
                        return rangeValue
                    }
                    return nil
                }
                if !validRanges.isEmpty {
                    textView.selectedRanges = validRanges
                }
            }
            
            context.coordinator.lastLogCount = logs.count
            
            // Auto-scroll to bottom if enabled
            if autoScroll && !logs.isEmpty {
                DispatchQueue.main.async {
                    textView.scrollToEndOfDocument(nil)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func buildAttributedString(from logs: [LogEntry]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        let timestampAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        let normalMessageAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.textColor
        ]
        
        let errorMessageAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.systemRed
        ]
        
        for entry in logs {
            // Timestamp
            let timestamp = NSAttributedString(
                string: entry.formattedTimestamp + "  ",
                attributes: timestampAttributes
            )
            result.append(timestamp)
            
            // Message
            let messageAttributes = entry.isError ? errorMessageAttributes : normalMessageAttributes
            let message = NSAttributedString(
                string: entry.message + "\n",
                attributes: messageAttributes
            )
            result.append(message)
        }
        
        return result
    }
    
    class Coordinator {
        var textView: NSTextView?
        var scrollView: NSScrollView?
        var lastLogCount: Int = 0
    }
}
