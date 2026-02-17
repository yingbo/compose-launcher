# Architecture Overview

Compose Launcher is a native macOS application built using **SwiftUI** and the **Swift Package Manager**. This document outlines the high-level architecture and design patterns used in the project. The UI/UX design is maintained in [Stitch](https://stitch.withgoogle.com/projects/12642404483796731361).

## Package Layout

- **`ComposeLauncher/Sources/App`**: App entrypoint (`ComposeLauncherApp.swift`).
- **`ComposeLauncher/Sources/Core`**: Shared application logic.
  - **`Managers`**: Docker/process and settings persistence logic.
  - **`Models`**: Codable app state and runtime model types.
  - **`Protocols`**: Abstractions used for testing/mocking.
  - **`Views`**: SwiftUI screens and view composition.
- **`ComposeLauncher/Tests`**: Unit and integration tests.

## Core Components

### Models (`ComposeLauncher/Sources/Core/Models`)
- **`ComposeFile`**: Represents a compose file and optional custom env-file path.
- **`AppSettings`**: Persisted settings (docker path, log limits, sidebar mode, saved files).
- **`LogEntry`**: Single log line with compose file association.

### Managers (`ComposeLauncher/Sources/Core/Managers`)
- **`DockerComposeManager`**: The core logic for interacting with the `docker compose` CLI. It handles starting/stopping containers, streaming logs, discovering services, and **managing environment files** (.env).
- **`SettingsManager`**: Manages the persistence of app settings and the list of imported compose files.

### Views (`ComposeLauncher/Sources/Core/Views`)
- **`ContentView`**: The main entry point that coordinates the Sidebar and Detail views.
- **`SidebarView`**: Lists imported compose files and provides management actions.
- **`EditorView`**: Provides a text editor for modifying YAML files.
- **`LogPanelView`**: Displays real-time logs with filtering capabilities.
- **`SettingsView`**: App-level settings (docker executable path, log limits, display mode).

## Data Flow

1. **Startup**: `SettingsManager` loads state from `~/Library/Application Support/ComposeLauncher/settings.yaml`.
2. **Commands**: User actions in SwiftUI views call manager methods.
3. **State Updates**: `DockerComposeManager` updates its published properties (e.g., running state, log buffer).
4. **UI Refresh**: SwiftUI observes these changes and updates the `Views` automatically.

## External Dependencies

- **Docker CLI**: The app relies on `docker compose` being installed on the host system. It executes commands via `Process`.
- **Yams**: YAML encoding/decoding for persisted settings.
