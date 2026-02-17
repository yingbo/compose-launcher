import SwiftUI

struct ServicesView: View {
    @ObservedObject var composeManager: DockerComposeManager
    @ObservedObject var settingsManager: SettingsManager
    @Binding var selectedFile: ComposeFile?

    @State private var allServices: [ServiceInfo] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var refreshTimer: Timer?
    @State private var lastRefresh: Date = Date()
    @State private var refreshTask: Task<Void, Never>?
    @State private var cachedConflicts: Set<PortBinding> = []
    @State private var refreshError: String?

    private var filteredServices: [ServiceInfo] {
        guard !searchText.isEmpty else { return allServices }
        let query = searchText
        return allServices.filter { service in
            service.Service.localizedCaseInsensitiveContains(query)
                || service.Name.localizedCaseInsensitiveContains(query)
                || service.Ports.localizedCaseInsensitiveContains(query)
                || (service.composeFileDisplayName ?? "").localizedCaseInsensitiveContains(query)
                || service.Publishers.contains { String($0.PublishedPort).contains(query) }
        }
    }

    /// A binding key that considers address, port, and protocol to avoid false positives.
    struct PortBinding: Hashable {
        let url: String
        let port: Int
        let proto: String
    }

    private var conflictCount: Int {
        cachedConflicts.count
    }

    private func isConflicted(_ pub: PortPublisher) -> Bool {
        cachedConflicts.contains(PortBinding(url: pub.URL, port: pub.PublishedPort, proto: pub.Protocol))
    }

    /// Parse host bindings from Docker Compose `Ports` text (e.g. "0.0.0.0:8080->80/tcp, :::443->443/tcp").
    /// Used as a fallback for conflict detection when `Publishers` is absent.
    static func parsePortBindings(from portsText: String) -> [PortBinding] {
        let portEntries = portsText.components(separatedBy: ", ")
        var bindings: [PortBinding] = []
        for entry in portEntries {
            guard let arrowRange = entry.range(of: "->") else { continue }
            let left = String(entry[entry.startIndex..<arrowRange.lowerBound])
            let right = String(entry[arrowRange.upperBound...])

            let rightParts = right.split(separator: "/", maxSplits: 1)
            let proto = rightParts.count > 1 ? String(rightParts[1]) : "tcp"

            guard let lastColon = left.lastIndex(of: ":") else { continue }
            let hostPart = String(left[left.startIndex..<lastColon])
            guard let port = Int(left[left.index(after: lastColon)...]), port > 0 else { continue }

            bindings.append(PortBinding(url: hostPart, port: port, proto: proto))
        }
        return bindings
    }

    private static func computeConflicts(from services: [ServiceInfo]) -> Set<PortBinding> {
        var bindingCount: [PortBinding: Int] = [:]
        for service in services {
            if !service.Publishers.isEmpty {
                for pub in service.Publishers where pub.PublishedPort > 0 {
                    let binding = PortBinding(url: pub.URL, port: pub.PublishedPort, proto: pub.Protocol)
                    bindingCount[binding, default: 0] += 1
                }
            } else if !service.Ports.isEmpty {
                for binding in parsePortBindings(from: service.Ports) {
                    bindingCount[binding, default: 0] += 1
                }
            }
        }
        return Set(bindingCount.filter { $0.value > 1 }.keys)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                Text("Running Services")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                    TextField("Search services or ports...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .accessibilityIdentifier("services-search-field")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(6)
                .frame(width: 220)

                Button(action: { scheduleRefresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .help("Refresh services")
                .accessibilityIdentifier("services-refresh-button")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Port conflict banner
            if conflictCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    Text("\(conflictCount) port conflict\(conflictCount == 1 ? "" : "s") detected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))

                Divider()
            }

            // Error banner
            if let error = refreshError {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                    Text(error)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .lineLimit(2)
                    Spacer()
                    Button(action: { refreshError = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))

                Divider()
            }

            // Content
            if isLoading && allServices.isEmpty {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            } else if filteredServices.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "network")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(allServices.isEmpty ? "No Running Services" : "No Matching Services")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(allServices.isEmpty
                         ? "Start a compose project to see services here."
                         : "Try a different search term.")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ServiceHeaderRow()
                        Divider()

                        ForEach(filteredServices) { service in
                            ServiceRow(
                                service: service,
                                isPortConflicted: isConflicted,
                                onNavigate: { navigateToFile(service) }
                            )
                            Divider().opacity(0.5)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }

            // Status bar
            HStack {
                Text("\(filteredServices.count) service\(filteredServices.count == 1 ? "" : "s")")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                if conflictCount > 0 {
                    Text("|")
                        .foregroundColor(.secondary.opacity(0.5))
                        .font(.system(size: 10))
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    Text("\(conflictCount) conflict\(conflictCount == 1 ? "" : "s")")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }

                Spacer()

                Text("Updated \(lastRefresh.formatted(.dateTime.hour().minute().second()))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .onAppear {
            scheduleRefresh()
            startAutoRefresh()
        }
        .onDisappear {
            refreshTask?.cancel()
            stopAutoRefresh()
        }
    }

    // MARK: - Data

    private func scheduleRefresh() {
        guard !isLoading else { return }
        refreshTask = Task {
            await performRefresh()
        }
    }

    private func performRefresh() async {
        isLoading = true
        defer { isLoading = false }
        var collected: [ServiceInfo] = []
        var errors: [String] = []

        for file in settingsManager.settings.composeFiles {
            if Task.isCancelled { return }
            do {
                let services = try await composeManager.getDetailedRunningServices(for: file)
                collected.append(contentsOf: services)
            } catch {
                errors.append("\(file.displayName): \(error.localizedDescription)")
            }
        }

        guard !Task.isCancelled else { return }
        allServices = collected
        cachedConflicts = Self.computeConflicts(from: collected)
        refreshError = errors.isEmpty ? nil : errors.joined(separator: "; ")
        lastRefresh = Date()
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task { @MainActor in
                // Skip tick if a refresh is already in-flight to avoid
                // cancelling work and potentially starving updates
                guard !isLoading else { return }
                scheduleRefresh()
            }
        }
    }

    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Navigation

    private func navigateToFile(_ service: ServiceInfo) {
        guard let fileId = service.composeFileId else { return }
        if let file = settingsManager.settings.composeFiles.first(where: { $0.id == fileId }) {
            selectedFile = file
        }
    }
}

// MARK: - Header Row

private struct ServiceHeaderRow: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Service")
                .frame(width: 140, alignment: .leading)
            Text("Status")
                .frame(width: 100, alignment: .leading)
            Text("Ports")
                .frame(minWidth: 200, alignment: .leading)
            Spacer()
            Text("Project")
                .frame(width: 150, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

// MARK: - Service Row

private struct ServiceRow: View {
    let service: ServiceInfo
    let isPortConflicted: (PortPublisher) -> Bool
    let onNavigate: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Service name with status dot
            HStack(spacing: 6) {
                Circle()
                    .fill(service.State == "running" ? Color.green : Color.gray)
                    .frame(width: 6, height: 6)
                Text(service.Service)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .frame(width: 140, alignment: .leading)

            // Status
            Text(service.Status.isEmpty ? service.State : service.Status)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)

            // Ports
            portsView
                .frame(minWidth: 200, alignment: .leading)

            Spacer()

            // Project name (clickable)
            Button(action: onNavigate) {
                HStack(spacing: 4) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 10))
                    Text(service.composeFileDisplayName ?? "Unknown")
                        .font(.system(size: 11))
                        .lineLimit(1)
                }
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("Navigate to \(service.composeFileDisplayName ?? "compose file")")
            .frame(width: 150, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var portsView: some View {
        let published = service.Publishers.filter { $0.PublishedPort > 0 }
        if published.isEmpty && !service.Ports.isEmpty {
            // Fallback: show raw Ports text when Publishers array is absent/empty
            Text(service.Ports)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary)
        } else if published.isEmpty {
            Text("No published ports")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(published) { pub in
                    HStack(spacing: 4) {
                        if isPortConflicted(pub) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.orange)
                        }
                        Text("\(pub.URL):\(pub.PublishedPort) \u{2192} \(pub.TargetPort)/\(pub.`Protocol`)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(isPortConflicted(pub) ? .orange : .primary)
                    }
                }
            }
        }
    }
}
