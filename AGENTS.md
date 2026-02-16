# Agent Rules for Compose Launcher

## Git Workflow

### Worktrees
- **Do NOT create git worktrees unless absolutely necessary**
- Work directly in the main worktree for all changes
- Only create worktrees if there's a specific technical requirement that cannot be met otherwise
- If a worktree is created, clean it up immediately after use

## Project Overview

This is a native macOS application (Compose Launcher) built with Swift/SwiftUI for managing Docker Compose projects.

## Development Guidelines

- Follow existing code patterns and structure
- Test changes before committing
- Maintain compatibility with macOS 14.0 or later
- Support both Intel and Apple Silicon Macs
