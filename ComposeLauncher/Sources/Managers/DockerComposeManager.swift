import Foundation

@MainActor
class DockerComposeManager: ObservableObject {
    @Published var logs: [LogEntry] = []
    @Published var runningProcesses: [UUID: Process] = [:]
    
    private var maxLogLines: Int = 100_000
    private var dockerPath: String = "/usr/local/bin/docker"
    
    static let shared = DockerComposeManager()
    
    func configure(maxLogLines: Int, dockerPath: String) {
        self.maxLogLines = maxLogLines
        self.dockerPath = dockerPath
    }
    
    func startCompose(for file: ComposeFile) async throws {
        guard runningProcesses[file.id] == nil else {
            addLog(for: file.id, message: "Already running", isError: true)
            return
        }
        
        let executableURL = URL(fileURLWithPath: dockerPath)
        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            let errorMsg = "Docker executable not found at: \(dockerPath). Please check Settings."
            addLog(for: file.id, message: errorMsg, isError: true)
            throw NSError(domain: "DockerComposeManager", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = executableURL
        process.arguments = ["compose", "-f", file.path, "up"]
        process.currentDirectoryURL = URL(fileURLWithPath: file.path).deletingLastPathComponent()
        process.standardOutput = pipe
        process.standardError = errorPipe
        setupEnvironment(for: process)
        
        runningProcesses[file.id] = process
        
        addLog(for: file.id, message: "Starting docker compose...")
        
        // Handle stdout
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                Task { @MainActor in
                    self?.processOutput(output, for: file.id, isError: false)
                }
            }
        }
        
        // Handle stderr
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                Task { @MainActor in
                    self?.processOutput(output, for: file.id, isError: true)
                }
            }
        }
        
        process.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                self?.runningProcesses.removeValue(forKey: file.id)
                self?.addLog(for: file.id, message: "Process terminated")
            }
        }
        
        do {
            try process.run()
        } catch {
            runningProcesses.removeValue(forKey: file.id)
            addLog(for: file.id, message: "Failed to start: \(error.localizedDescription)", isError: true)
            throw error
        }
    }
    
    func stopCompose(for file: ComposeFile) async {
        // First terminate the running process
        if let process = runningProcesses[file.id] {
            process.terminate()
            runningProcesses.removeValue(forKey: file.id)
        }
        
        // Then run docker compose down
        addLog(for: file.id, message: "Stopping containers...")
        
        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: dockerPath)
        process.arguments = ["compose", "-f", file.path, "down"]
        process.currentDirectoryURL = URL(fileURLWithPath: file.path).deletingLastPathComponent()
        process.standardOutput = pipe
        process.standardError = errorPipe
        setupEnvironment(for: process)
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8), !output.isEmpty {
                processOutput(output, for: file.id, isError: false)
            }
            if let errorOutput = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8), !errorOutput.isEmpty {
                processOutput(errorOutput, for: file.id, isError: true)
            }
            
            addLog(for: file.id, message: "Containers stopped")
        } catch {
            addLog(for: file.id, message: "Failed to stop: \(error.localizedDescription)", isError: true)
        }
    }
    
    func isRunning(_ file: ComposeFile) -> Bool {
        return runningProcesses[file.id] != nil
    }
    
    func clearLogs(for fileId: UUID? = nil) {
        if let fileId = fileId {
            logs.removeAll { $0.composeFileId == fileId }
        } else {
            logs.removeAll()
        }
    }
    
    private func processOutput(_ output: String, for fileId: UUID, isError: Bool) {
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        for line in lines {
            addLog(for: fileId, message: line, isError: isError)
        }
    }
    
    private func addLog(for fileId: UUID, message: String, isError: Bool = false) {
        let entry = LogEntry(composeFileId: fileId, message: message, isError: isError)
        logs.append(entry)
        
        // Trim logs if exceeding max
        if logs.count > maxLogLines {
            logs.removeFirst(logs.count - maxLogLines)
        }
    }
    
    private func setupEnvironment(for process: Process) {
        var env = ProcessInfo.processInfo.environment
        let commonPaths = ["/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin", "/opt/homebrew/bin"]
        let currentPath = env["PATH"] ?? ""
        let pathList = currentPath.split(separator: ":").map(String.init)
        var newPaths = pathList
        for path in commonPaths {
            if !newPaths.contains(path) {
                newPaths.insert(path, at: 0)
            }
        }
        env["PATH"] = newPaths.joined(separator: ":")
        process.environment = env
    }
}
