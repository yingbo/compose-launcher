# AI Agent Rules

## GitHub Issue (Ticket) Workflow

Follow this strict workflow when working on a GitHub issue (ticket):

1.  **Create Feature Branch**: Always create a new feature branch for the ticket (e.g., `feature/issue-123-description`).
2.  **Implementation**: Work entirely on the feature branch. Implement the requested changes in the code.
3.  **Update Ticket**: Record what you did by adding a comment to the GitHub issue.
4.  **Update Documents**: Update any related documentation (e.g., README.md, ARCHITECTURE.md) to reflect the changes.
5.  **Commit & Push**: Commit your changes. **Crucial**: The commit message MUST mention the ticket number (e.g., `Implement feature X (#123)`), so we can navigate from the ticket to the commits. Push the branch to the remote.
6.  **Submit MR (PR)**: Create a Pull Request (Merge Request).
    *   Do **NOT** merge the PR yourself.
    *   Do **NOT** close the ticket yourself.
    *   The USER will check the result, merge the PR, and close the ticket.
7.  **Auto-Run Allowed**: Since work is isolated in a new feature branch, you are authorized to **auto-run** (`SafeToAutoRun: true`) the commands for committing, pushing, and creating the Merge Request (PR).

## Design Rules

When creating designs (e.g., using Stitch), follow these principles:

1.  **Default Theme**: Use **Light Theme** as the default for all new design screens unless explicitly requested otherwise.
2.  **Typography**: Use **macOS standard interface fonts** (e.g., San Francisco/System Font) for all text elements to ensure a native look and feel.

