# Compose Launcher

A lightweight GUI to start, stop, and manage Docker Compose stacks. Perfect for developers running multiple compose files locally.

- Visual stack management
- Start / stop environments in one click
- Lightweight alternative to Docker Desktop
- Built for local development workflows

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Docker Compose](https://img.shields.io/badge/docker-compose-orange)
![Status](https://img.shields.io/badge/status-active-brightgreen)

## Why Compose Launcher

- Manage multiple Docker Compose projects from one app
- See all running services across projects at a glance
- Stream and search logs without terminal clutter
- Edit Compose YAML directly inside the app
- Designed for local multi-stack development on macOS

Who is this for?

- Developers running multiple compose environments
- Teams with several local services
- People who don't want to memorize docker-compose commands

## The Problem

When you work across multiple local Docker Compose projects, the terminal workflow gets messy fast:

- too many terminal tabs and windows
- hard to remember which stacks are running
- logs scattered across sessions
- editing Compose files and monitoring services happen in different tools

## The Solution

Compose Launcher centralizes your local Compose workflow in one macOS app. You can manage projects in a sidebar, control runtime state, inspect logs, and edit YAML from the same interface. This reduces terminal hopping and makes multi-stack development easier to track.

## Why not just use the CLI?

`docker compose` works well for individual projects, but local development gets harder when you are managing multiple stacks at once. Compose Launcher gives you a single place to track projects, inspect logs, and edit Compose files without bouncing between terminal sessions and windows.

## Features

## Features

Core capabilities:

- Manage multiple Compose projects
- Start/stop stacks from one interface
- Stream and search logs
- Built-in Compose YAML editor
- `.env` file support

### Project Management

- Import and manage multiple Compose files (including `compose.yaml`, `docker-compose.yml`, and custom filenames)
- Directory-aware sidebar tree for quick navigation
- `.env` file support (auto-detect or custom path per project)
- Persistent settings stored in YAML

### Runtime Control

- Start and stop selected Compose projects
- Service status visibility in one interface

### Logs & Debugging

- Live log streaming
- Search and filter logs
- Configurable log retention (default: 100,000 lines)

### Editing

- Built-in YAML editor with save support
- External editor integration

## Requirements

- macOS 14.0 or later
- Docker Desktop installed and running
- Xcode 15+ (if building from source)

## Installation

### Option 1: Download a release build

Download the latest `Compose-Launcher-macos.zip` from this repository's [Releases](../../releases) page. Extract it, then launch `Compose Launcher.app`.

Code signing note: release builds are unsigned. On first launch, right-click and choose **Open**, or run:

```bash
xattr -cr "Compose Launcher.app"
```

### Option 2: Build from source

You can also build locally from source:

```bash
./build-app.sh
```

This creates `Compose Launcher.app` and launches it.

Alternative manual build:

```bash
cd ComposeLauncher
swift build -c release
```

Binary output:

```text
ComposeLauncher/.build/release/ComposeLauncher
```

## Quick Start

1. Launch the app.
2. Click **Add Compose File** (⌘O).
3. Select your `compose.yaml` or `docker-compose.yml`.
4. Click **Start Selected** (⌘R).
5. View logs or edit configuration from the sidebar.

## Interface Preview

![Main Window](docs/screenshots/mainwindow.png)
![Running Services](docs/screenshots/services.png)
![Built-in Editor](docs/screenshots/editor.png)
![Settings](docs/screenshots/settings.png)

## Use Cases

- Microservice development with multiple local stacks
- Managing several Compose projects at the same time
- Switching between local environments quickly
- Using a GUI workflow for day-to-day Docker Compose tasks

## Who This Is For

Compose Launcher is useful if you:

- run multiple Docker Compose projects locally
- work on microservice architectures
- prefer a GUI over managing stacks purely in terminal
- frequently switch between local environments

## Comparison

| Option | Best for |
|--------|----------|
| `docker compose` CLI | Operating one project at a time from terminal |
| Compose Launcher | Managing multiple projects with GUI controls, logs, and editor |

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Add Compose File | `⌘O` |
| Start Selected | `⌘R` |
| Stop Selected | `⌘.` |
| Save Editor | `⌘S` |
| Settings | `⌘,` |

## Roadmap

Planned improvements:

- richer project grouping and workspace organization
- deeper service health/status visibility
- expanded log tooling
- packaging/distribution improvements

## Documentation

- [Architecture](ARCHITECTURE.md)
- [FAQ](FAQ.md)
- [Contributing](CONTRIBUTING.md)
- [Release Process](RELEASES.md)

## Contributing

Contributions are welcome. Please open an issue or submit a pull request.

## License

MIT License
