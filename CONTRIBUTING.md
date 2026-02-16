# Contributing to Compose Launcher

Thank you for your interest in contributing to Compose Launcher! This document provides guidelines and instructions for contributing to this project.

## Getting Started

### Development Prerequisites

- macOS 14.0 or later
- Xcode 15+
- Docker Desktop (required for integration tests)

### Setup

1. Clone the repository:
   ```bash
   git clone <your-fork-or-repo-url>
   cd compose-launcher
   ```

2. Open the package in Xcode:
   ```bash
   open ComposeLauncher/Package.swift
   ```

3. Build and run tests:
   ```bash
   ./tests/run-tests-mock.sh
   ```
   For Docker-backed integration tests:
   ```bash
   ./tests/run-tests.sh
   ```

## Code Guidelines

- Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- Use 4 spaces for indentation.
- Prefer `struct` for data models and `class` (with `@Observable` or `ObservableObject`) for managers and state.
- Keep views small and modular.

## Project Structure

- **`ComposeLauncher/Sources/App`**: App entrypoint.
- **`ComposeLauncher/Sources/Core/Models`**: Data structures and persisted types.
- **`ComposeLauncher/Sources/Core/Managers`**: Docker interaction and settings persistence.
- **`ComposeLauncher/Sources/Core/Views`**: SwiftUI components and screens.
- **`ComposeLauncher/Tests`**: Unit/integration tests.

For design details and runtime architecture, see [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Commit Message Guidelines

When working on issues, include the issue number in your commit messages to automatically link commits to issues:

- **Reference an issue**: Use `#issue-number` in the commit message
  - Example: `Add rename functionality for flat view (#9)`
- **Close an issue**: Use `Fixes #issue-number`, `Closes #issue-number`, or `Resolves #issue-number`
  - Example: `Implement folder/filename naming for flat view\n\nFixes #9`
  - The issue will be automatically closed when the PR is merged to main

**Good commit message format:**
```
Brief summary of changes

- Detailed point 1
- Detailed point 2
- Detailed point 3

Fixes #issue-number
```

## Pull Request Process

1. Create a new branch for your feature or bug fix:
   - If related to an issue: `git checkout -b feature/issue-number-brief-description`
     - Example: `git checkout -b feature/9-flat-view-naming`
   - If not related to an issue: `git checkout -b feature/your-feature-name`
2. Make your changes and ensure the project builds correctly.
3. Commit your changes with descriptive messages (see Commit Message Guidelines above).
4. Push to your fork and submit a Pull Request.

## Reporting Issues

Use the GitHub Issue Tracker to report bugs or suggest new features. Please provide as much detail as possible, including steps to reproduce bugs.
