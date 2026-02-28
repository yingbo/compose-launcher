# Agent Rules for Compose Launcher

## Git Workflow

### Branching
- Create a feature branch for issue-driven work (example: `feature/issue-123-description`)
- Implement changes on that feature branch
- Do not merge PRs yourself; the user will review and merge
- Do not close issues yourself; the user will close them

### Commits
- NEVER add `Co-Authored-By` lines in commit messages
- The repository owner must be the sole contributor; do not attribute commits to AI assistants

### Worktrees
- **Do NOT create git worktrees unless absolutely necessary**
- Work directly in the main worktree for all changes
- Only create worktrees if there's a specific technical requirement that cannot be met otherwise
- If a worktree is created, clean it up immediately after use

### Issue/Ticket Workflow
1. Create a feature branch for the ticket.
2. Implement the requested changes.
3. Add a progress/result comment to the related GitHub issue.
4. Update relevant docs when behavior or workflows change.
5. Commit and push changes; include the ticket number in commit messages (example: `Implement feature X (#123)`).
6. Open a Pull Request.
7. Do not merge the PR or close the ticket.

## Project Overview

This is a native macOS application (Compose Launcher) built with Swift/SwiftUI for managing Docker Compose projects.

## Development Guidelines

- Follow existing code patterns and structure
- Test changes before committing
- Maintain compatibility with macOS 14.0 or later
- Support both Intel and Apple Silicon Macs
- Use `./build-app.sh` to build the release app bundle and launch it
- Use Peekaboo (via global `~/.mcp.json` or CLI) to capture screenshots of the running app

## Design Rules

- Use light theme by default unless explicitly requested otherwise
- Use macOS native typography (San Francisco/system font) for native-feeling UI
