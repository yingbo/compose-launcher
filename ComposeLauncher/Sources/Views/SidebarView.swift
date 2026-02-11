import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var composeManager: DockerComposeManager
    @Binding var selectedFile: ComposeFile?
    @State private var showingFilePicker = false
    @State private var hoveredFileId: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Compose Files")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showingFilePicker = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help("Add Compose File")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // File List
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(settingsManager.settings.composeFiles) { file in
                        ComposeFileRow(
                            file: file,
                            isSelected: selectedFile?.id == file.id,
                            isRunning: composeManager.isRunning(file),
                            isHovered: hoveredFileId == file.id,
                            onSelect: { selectedFile = file },
                            onStart: { startCompose(file) },
                            onStop: { stopCompose(file) },
                            onRemove: { removeFile(file) }
                        )
                        .onHover { isHovered in
                            hoveredFileId = isHovered ? file.id : nil
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
        }
        .frame(minWidth: 240)
        .background(Color(nsColor: .controlBackgroundColor))
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.yaml, .init(filenameExtension: "yml")!],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result)
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                
                // Check if file already exists
                let existingPaths = settingsManager.settings.composeFiles.map { $0.path }
                guard !existingPaths.contains(url.path) else { continue }
                
                let file = ComposeFile(
                    name: url.deletingLastPathComponent().lastPathComponent,
                    path: url.path
                )
                settingsManager.addComposeFile(file)
                selectedFile = file
            }
            
        case .failure(let error):
            print("File selection error: \(error)")
        }
    }
    
    private func startCompose(_ file: ComposeFile) {
        Task {
            try? await composeManager.startCompose(for: file)
        }
    }
    
    private func stopCompose(_ file: ComposeFile) {
        Task {
            await composeManager.stopCompose(for: file)
        }
    }
    
    private func removeFile(_ file: ComposeFile) {
        if composeManager.isRunning(file) {
            Task {
                await composeManager.stopCompose(for: file)
                settingsManager.removeComposeFile(file)
                if selectedFile?.id == file.id {
                    selectedFile = nil
                }
            }
        } else {
            settingsManager.removeComposeFile(file)
            if selectedFile?.id == file.id {
                selectedFile = nil
            }
        }
    }
}

struct ComposeFileRow: View {
    let file: ComposeFile
    let isSelected: Bool
    let isRunning: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onStart: () -> Void
    let onStop: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // Status indicator
            Circle()
                .fill(isRunning ? Color.green : Color.gray.opacity(0.4))
                .frame(width: 8, height: 8)
                .shadow(color: isRunning ? .green.opacity(0.5) : .clear, radius: 3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(file.path)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            if isHovered || isSelected {
                HStack(spacing: 6) {
                    if isRunning {
                        Button(action: onStop) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Stop")
                    } else {
                        Button(action: onStart) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                        .help("Start")
                    }
                    
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : (isHovered ? Color.primary.opacity(0.05) : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}
