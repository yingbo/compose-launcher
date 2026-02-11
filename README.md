# Compose Launcher

A native macOS application for managing and running Docker Compose files with a beautiful SwiftUI interface.

## Documentation

- [Architecture](ARCHITECTURE.md) - High-level overview of the app's design
- [FAQ](FAQ.md) - Common questions and answers
- [Contributing](CONTRIBUTING.md) - Guide for developers
- [License](LICENSE) - Legal information

## Features

- **Add & Manage Compose Files**: Import any `docker-compose.yml` file and manage them from a sidebar
- **Built-in Editor**: Edit compose files directly in the app with syntax highlighting
- **Live Logs**: View real-time logs from running containers with search and filtering
- **Log Management**: Configurable log retention (default: 100,000 lines)
- **External Editor Support**: Open compose files in your preferred external editor
- **Persistent Settings**: All settings saved in YAML format

## Requirements

- macOS 14.0 (Sonoma) or later
- Docker Desktop installed and running
- Xcode 15+ (for building from source)

## Building

### Using Swift Package Manager

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

### Adding Compose Files

1. Click the **+** button in the sidebar
2. Select a `docker-compose.yml` file
3. The file will appear in your sidebar

### Running Containers

1. Select a compose file from the sidebar
2. Click the **▶** (play) button to start
3. View logs in the **Logs** tab
4. Click the **■** (stop) button to stop containers

### Editing Compose Files

1. Select a compose file
2. Switch to the **Editor** tab
3. Make your changes
4. Press **⌘S** or click **Save**

### Settings

Access settings via:
- **⌘,** keyboard shortcut
- Gear icon in the toolbar
- **Compose Launcher → Settings** menu

Configure:
- Docker executable path
- Maximum log lines to retain

## File Locations

- **Settings**: `~/Library/Application Support/ComposeLauncher/settings.yaml`

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
