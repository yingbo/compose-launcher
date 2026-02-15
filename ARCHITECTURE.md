# Architecture Overview

Compose Launcher is a native macOS application built using **SwiftUI** and the **Swift Package Manager**. This document outlines the high-level architecture and design patterns used in the project. The UI/UX design is maintained in [Stitch](https://stitch.withgoogle.com/projects/12642404483796731361).

## Components

### 1. Models (`Sources/Models`)
These are simple, immutable data structures that represent the core entities of the application.
- **`ComposeFile`**: Represents a `docker-compose.yml` file, its location, and its current state.
- **`AppSettings`**: Configuration settings for the app, including **`SidebarDisplayMode`** (Flat or Hierarchical).
- **`LogEntry`**: A single line of log output from a container.

### 2. Managers (`Sources/Managers`)
Managers handle the business logic and interact with external systems (Docker, Filesystem).
- **`DockerComposeManager`**: The core logic for interacting with the `docker compose` CLI. It handles starting/stopping containers, streaming logs, discovering services, and **managing environment files** (.env).
- **`SettingsManager`**: Manages the persistence of app settings and the list of imported compose files.

### 3. Views (`Sources/Views`)
SwiftUI views that provide the user interface. We use a modular approach:
- **`ContentView`**: The main entry point that coordinates the Sidebar and Detail views.
- **`SidebarView`**: Lists imported compose files and provides management actions.
- **`EditorView`**: Provides a text editor for modifying YAML files.
- **`LogPanelView`**: Displays real-time logs with filtering capabilities.

## Data Flow

1. **Persistence**: `SettingsManager` loads the app state from a YAML file in `Application Support`.
2. **Commands**: User actions in the `Views` trigger methods in `DockerComposeManager`.
3. **State Updates**: `DockerComposeManager` updates its published properties (e.g., running state, log buffer).
4. **UI Refresh**: SwiftUI observes these changes and updates the `Views` automatically.

## External Dependencies

- **Docker CLI**: The app relies on `docker compose` being installed on the host system. It executes commands via `Process`.
- **Swift Package Manager**: All dependencies (if any) are managed through `Package.swift`.
