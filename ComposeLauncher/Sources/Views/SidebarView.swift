import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var composeManager: DockerComposeManager
    @Binding var selectedFile: ComposeFile?
    @State private var showingFilePicker = false
    @State private var hoveredFileId: UUID?
    @State private var showingDeleteConfirmation = false
    @State private var fileToDelete: ComposeFile?
    @State private var expandedItems: Set<String> = []
    @State private var cachedServices: [UUID: [String]] = [:]
    @State private var runningServices: [UUID: [String]] = [:]
    
    struct SidebarItem: Identifiable {
        let id: String
        let name: String
        let icon: String
        let file: ComposeFile?
        let isService: Bool
        let children: [SidebarItem]?
    }
    
    private var treeItems: [SidebarItem] {
        var folders: [String: [ComposeFile]] = [:]
        
        for file in settingsManager.settings.composeFiles {
            let parentPath = URL(fileURLWithPath: file.path).deletingLastPathComponent().path
            folders[parentPath, default: []].append(file)
        }
        
        return folders.map { (path, files) in
            let folderName = URL(fileURLWithPath: path).lastPathComponent
            return SidebarItem(
                id: path,
                name: folderName,
                icon: "folder.fill",
                file: nil,
                isService: false,
                children: files.map { file in
                    let services = cachedServices[file.id] ?? []
                    return SidebarItem(
                        id: file.id.uuidString,
                        name: file.displayName,
                        icon: "shippingbox.fill",
                        file: file,
                        isService: false,
                        children: services.isEmpty ? nil : services.map { service in
                            SidebarItem(
                                id: "\(file.id.uuidString)-\(service)",
                                name: service,
                                icon: "cpu",
                                file: file, // Keep track of parent file
                                isService: true,
                                children: nil
                            )
                        }
                    )
                }.sorted { $0.name < $1.name }
            )
        }.sorted { $0.name < $1.name }
    }
    
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
            if settingsManager.settings.sidebarDisplayMode == .tree {
                List(treeItems, children: \.children) { item in
                    SidebarRow(
                        item: item,
                        selectedFile: $selectedFile,
                        hoveredId: $hoveredFileId,
                        isRunning: item.file.map { composeManager.isRunning($0) } ?? false,
                        isServiceRunning: item.isService && item.file.map { runningServices[$0.id]?.contains(item.name) ?? false } ?? false,
                        onStart: { if let file = item.file { startCompose(file) } },
                        onStop: { if let file = item.file { stopCompose(file) } },
                        onRemove: {
                            if let file = item.file {
                                fileToDelete = file
                                showingDeleteConfirmation = true
                            }
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                }
                .listStyle(.sidebar)
            } else {
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
                                onRemove: {
                                    fileToDelete = file
                                    showingDeleteConfirmation = true
                                }
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
        }
        .onAppear {
            refreshAllServices()
        }
        .frame(minWidth: 240)
        .background(Color(nsColor: .controlBackgroundColor))
        .alert("Remove Compose File", isPresented: $showingDeleteConfirmation, presenting: fileToDelete) { file in
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                removeFile(file)
            }
        } message: { file in
            Text("Are you sure you want to remove '\(file.displayName)'? This will not delete the file from your disk.")
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.yaml, .init(filenameExtension: "yml")!],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result)
        }
        .onReceive(NotificationCenter.default.publisher(for: .addComposeFile)) { _ in
            showingFilePicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .startCompose)) { _ in
            if let file = selectedFile {
                startCompose(file)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .stopCompose)) { _ in
            if let file = selectedFile {
                stopCompose(file)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .removeCompose)) { _ in
            if let file = selectedFile {
                fileToDelete = file
                showingDeleteConfirmation = true
            }
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
    
    private func refreshAllServices() {
        for file in settingsManager.settings.composeFiles {
            Task {
                let services = await composeManager.getServices(for: file)
                cachedServices[file.id] = services
                
                let running = await composeManager.getRunningServices(for: file)
                runningServices[file.id] = running
            }
        }
    }
}

struct SidebarRow: View {
    let item: SidebarView.SidebarItem
    @Binding var selectedFile: ComposeFile?
    @Binding var hoveredId: UUID?
    let isRunning: Bool
    let isServiceRunning: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            if item.file != nil || item.isService {
                Circle()
                    .fill(item.isService ? (isServiceRunning ? Color.green : Color.gray.opacity(0.4)) : (isRunning ? Color.green : Color.gray.opacity(0.4)))
                    .frame(width: 6, height: 6)
            } else {
                Image(systemName: item.icon)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Text(item.name)
                .font(.system(size: 13, weight: item.file != nil && !item.isService ? .medium : .regular))
                .foregroundColor(item.isService ? .secondary : .primary)
                .lineLimit(1)
            
            if !item.isService, let file = item.file, file.envFilePath != nil {
                Text(".env")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.accentColor.opacity(0.8))
                    .cornerRadius(3)
            }
            
            Spacer()
            
            if !item.isService && item.file != nil {
                if isRunning {
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: onStart) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let file = item.file {
                selectedFile = file
            }
        }
        .contextMenu {
            if item.file != nil && !item.isService {
                Button(role: .destructive, action: onRemove) {
                    Label("Remove", systemImage: "trash")
                }
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
                HStack(spacing: 4) {
                    Text(file.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if file.envFilePath != nil {
                        Text(".env")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.8))
                            .cornerRadius(3)
                    }
                }
                
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
        .contextMenu {
            Button(role: .destructive, action: onRemove) {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}
