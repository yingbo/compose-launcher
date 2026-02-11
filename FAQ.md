# Frequently Asked Questions (FAQ)

## File Management

### Where does the app save added compose files?
The app **does not copy or move** your compose files to a private location. Instead, it stores a **reference (the absolute file path)** to the original file in its settings.

Detailed behavior:
- **Settings Location:** The list of added files is stored in `~/Library/Application Support/ComposeLauncher/settings.yaml`.
- **Source of Truth:** The app reads directly from the original location you selected.
- **Editing:** If you use the built-in editor, it saves changes directly back to your original file.
- **External Changes:** If you modify the file with external tools, the app sees those changes because it points to the same underlying file.
