import Foundation

@MainActor
public class DockerComposeManager: DockerComposeManaging {
    @Published public var logs: [LogEntry] = []
    @Published public var runningProcesses: [UUID: Process] = [:]

    private var maxLogLines: Int = 100_000
    private var dockerPath: String = "/usr/local/bin/docker"

    public static let shared = DockerComposeManager()

    public init() {}

    public func configure(maxLogLines: Int, dockerPath: String) {
        self.maxLogLines = maxLogLines
        self.dockerPath = dockerPath
    }

    public func startCompose(for file: ComposeFile) async throws {
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
        process.arguments = ["compose", "-f", file.path] + getEnvFileArguments(for: file) + ["up"]
        process.currentDirectoryURL = URL(fileURLWithPath: file.path).deletingLastPathComponent()
        process.standardOutput = pipe
        process.standardError = errorPipe
        setupEnvironment(for: process)

        runningProcesses[file.id] = process

        addLog(for: file.id, message: "Starting docker compose...")

        // Capture file ID for closures
        let fileId = file.id

        // Handle stdout - use nonisolated helper to avoid concurrency issues
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                Task { @MainActor [weak self] in
                    self?.processOutput(output, for: fileId, isError: false)
                }
            }
        }

        // Handle stderr
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                Task { @MainActor [weak self] in
                    self?.processOutput(output, for: fileId, isError: true)
                }
            }
        }

        process.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.runningProcesses.removeValue(forKey: fileId)
                self?.addLog(for: fileId, message: "Process terminated")
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

    public func stopCompose(for file: ComposeFile) async {
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
        process.arguments = ["compose", "-f", file.path] + getEnvFileArguments(for: file) + ["down"]
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

    public func isRunning(_ file: ComposeFile) -> Bool {
        return runningProcesses[file.id] != nil
    }

    public func getServices(for file: ComposeFile) async -> [String] {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: dockerPath)
        process.arguments = ["compose", "-f", file.path] + getEnvFileArguments(for: file) + ["config", "--services"]
        process.currentDirectoryURL = URL(fileURLWithPath: file.path).deletingLastPathComponent()
        process.standardOutput = pipe
        setupEnvironment(for: process)

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
            }
        } catch {
            print("Failed to get services: \(error)")
        }
        return []
    }

    private struct BasicServiceInfo: Codable {
        let Service: String
        let State: String
    }

    public func getRunningServices(for file: ComposeFile) async -> [String] {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: dockerPath)
        process.arguments = ["compose", "-f", file.path] + getEnvFileArguments(for: file) + ["ps", "--format", "json"]
        process.currentDirectoryURL = URL(fileURLWithPath: file.path).deletingLastPathComponent()
        process.standardOutput = pipe
        setupEnvironment(for: process)

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()

            // Docker Compose ps --format json output can be multiple JSON objects or a list depending on version
            let output = String(data: data, encoding: .utf8) ?? ""
            if output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return [] }

            // Try parsing as a list first
            if let list = try? JSONDecoder().decode([BasicServiceInfo].self, from: data) {
                return list.filter { $0.State == "running" }.map { $0.Service }
            }

            // Handle line-delimited JSON
            let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
            var runningServices: [String] = []
            for line in lines {
                if let info = try? JSONDecoder().decode(BasicServiceInfo.self, from: line.data(using: .utf8)!) {
                    if info.State == "running" {
                        runningServices.append(info.Service)
                    }
                }
            }
            return runningServices
        } catch {
            print("Failed to get service statuses: \(error)")
        }
        return []
    }

    public func getDetailedRunningServices(for file: ComposeFile) async -> [ServiceInfo] {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: dockerPath)
        process.arguments = ["compose", "-f", file.path] + getEnvFileArguments(for: file) + ["ps", "--format", "json"]
        process.currentDirectoryURL = URL(fileURLWithPath: file.path).deletingLastPathComponent()
        process.standardOutput = pipe
        setupEnvironment(for: process)

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()

            let output = String(data: data, encoding: .utf8) ?? ""
            if output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return [] }

            var services: [ServiceInfo] = []

            // Try parsing as a JSON array first
            if let list = try? JSONDecoder().decode([ServiceInfo].self, from: data) {
                services = list
            } else {
                // Handle line-delimited JSON (older Docker Compose versions)
                let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
                for line in lines {
                    if let lineData = line.data(using: .utf8),
                       let info = try? JSONDecoder().decode(ServiceInfo.self, from: lineData) {
                        services.append(info)
                    }
                }
            }

            return services
                .filter { $0.State == "running" }
                .map { service in
                    var s = service
                    s.composeFileId = file.id
                    s.composeFilePath = file.path
                    s.composeFileDisplayName = file.displayName
                    return s
                }
        } catch {
            print("Failed to get detailed service statuses: \(error)")
        }
        return []
    }

    private func getEnvFileArguments(for file: ComposeFile) -> [String] {
        if let customEnv = file.envFilePath, !customEnv.isEmpty {
            return ["--env-file", customEnv]
        }

        // Default to .env in the same directory if it exists
        let composeDir = URL(fileURLWithPath: file.path).deletingLastPathComponent()
        let defaultEnvPath = composeDir.appendingPathComponent(".env").path
        if FileManager.default.fileExists(atPath: defaultEnvPath) {
            return ["--env-file", defaultEnvPath]
        }

        return []
    }

    public func clearLogs(for fileId: UUID? = nil) {
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
