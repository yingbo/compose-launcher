# Compose Launcher

A native macOS application for managing and running Docker Compose files with a clean SwiftUI interface.

## Screenshots

![Main Window](docs/screenshots/mainwindow.png)
![Built-in Editor](docs/screenshots/editor.png)
![Running Services](docs/screenshots/services.png)
![Settings](docs/screenshots/settings.png)

## Features

- **Add & Manage Compose Files**: Import any `docker-compose.yml` file and manage them from a sidebar
- **Hierarchical Tree View**: Organize files by their directory structure and monitor individual services
- **Built-in Editor**: Edit compose files directly in the app with syntax highlighting
- **Live Logs**: View real-time logs from running containers with search and filtering
- **Log Management**: Configurable log retention (default: 100,000 lines)
- **External Editor Support**: Open compose files in your preferred external editor
- **.env File Support**: Automatically picks up `.env` files in the same directory, or configure a custom environment file per project
- **Persistent Settings**: All settings saved in YAML format

## Requirements

- macOS 14.0 (Sonoma) or later
- Docker Desktop installed and running
- Xcode 15+ (for building from source)

## Build From Source

### App bundle (recommended)

```bash
./build-app.sh
```

### Swift Package Manager

```bash
cd ComposeLauncher
swift build -c release
```

The binary will be at `.build/release/ComposeLauncher`.

### Xcode

1. Open the `ComposeLauncher` folder in Xcode
2. Build with ⌘B, run with ⌘R

## Usage

1. Click **+** in the sidebar to add a `docker-compose.yml` file
2. Click **▶** to start and **■** to stop
3. Use the **Editor** tab to modify YAML and **Logs** to inspect container output

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Add Compose File | ⌘O |
| Start Selected | ⌘R |
| Stop Selected | ⌘. |
| Save Editor | ⌘S |
| Settings | ⌘, |

## Documentation

- [Architecture](ARCHITECTURE.md)
- [FAQ](FAQ.md)
- [Contributing](CONTRIBUTING.md)
- [Release Process](RELEASES.md)

## License

Free for personal use. Commercial use requires the author's permission — please open an issue to get in touch.
