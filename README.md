# Compose Launcher

A native macOS application for managing and running Docker Compose files with a beautiful SwiftUI interface.

## Documentation

- [Design (Stitch)](https://stitch.withgoogle.com/projects/12642404483796731361) - UI/UX design project
- [Architecture](ARCHITECTURE.md) - High-level overview of the app's design
- [FAQ](FAQ.md) - Common questions and answers
- [Contributing](CONTRIBUTING.md) - Guide for developers
- [Release Process](RELEASES.md) - How builds and GitHub releases are produced
- [License](LICENSE) - Legal information

## Features

- **Add & Manage Compose Files**: Import any `docker-compose.yml` file and manage them from a sidebar
- **Hierarchical Tree View**: Organize files by their directory structure and monitor individual services
- **Built-in Editor**: Edit compose files directly in the app with syntax highlighting
- **Live Logs**: View real-time logs from running containers with search and filtering
- **Log Management**: Configurable log retention (default: 100,000 lines)
- **External Editor Support**: Open compose files in your preferred external editor
- **.env File Support**: Automatically picks up `.env` files in the same directory, or allows selecting a custom environment file for each project
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

### Swift Package Manager binary

```bash
cd ComposeLauncher
swift build -c release
```

The built application will be in `.build/release/ComposeLauncher`.

### Using Xcode

1. Open the `ComposeLauncher` folder in Xcode
2. Select **Product → Build** (⌘B)
3. Run with **Product → Run** (⌘R)

## Usage

1. Click the **+** button in the sidebar
2. Select a `docker-compose.yml` file
3. Click **▶** to run and **■** to stop
4. Use **Editor** to modify YAML and **Logs** to inspect container output

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Add Compose File | ⌘O |
| Start Selected | ⌘R |
| Stop Selected | ⌘. |
| Save Editor | ⌘S |
| Settings | ⌘, |

## License

Private License
