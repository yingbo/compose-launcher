# Contributing to Compose Launcher

Thank you for your interest in contributing to Compose Launcher! This document provides guidelines and instructions for contributing to this project.

## Getting Started

### Prerequisites

- macOS 14.0 or later
- Xcode 15+
- Docker Desktop installed and running

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/compose-launcher.git
   cd compose-launcher
   ```

2. Open the `ComposeLauncher` directory in Xcode:
   ```bash
   open ComposeLauncher/Package.swift
   ```
   *Note: Xcode will automatically resolve dependencies.*

3. Run the project (⌘R).

## Code Style

- Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- Use 4 spaces for indentation.
- Prefer `struct` for data models and `class` (with `@Observable` or `ObservableObject`) for managers and state.
- Keep views small and modular.

## Project Structure

- **`Sources/Models`**: Plain data structures and enums.
- **`Sources/Managers`**: Business logic, Docker interaction, and persistence.
- **`Sources/Views`**: SwiftUI components and screens.

## Pull Request Process

1. Create a new branch for your feature or bug fix: `git checkout -b feature/your-feature-name`.
2. Make your changes and ensure the project builds correctly.
3. Commit your changes with descriptive messages.
4. Push to your fork and submit a Pull Request.

## Reporting Issues

Use the GitHub Issue Tracker to report bugs or suggest new features. Please provide as much detail as possible, including steps to reproduce bugs.
