# AI Agent Rules

## GitHub Issues & Branching Strategy

Whenever working on a GitHub issue, follow these steps:

1.  **Preparation**
    *   ALWAYS create a feature branch from `main` before starting work.
    *   Feature branches should follow the naming convention: `feature/issue-[number]-[description]`.
    *   Work ONLY on the feature branch. Do not commit directly to `main`.

2.  **Implementation**
    *   Complete the requested changes and verify them (build/test).

3.  **Completion & Documentation**
    *   **Update the Issue**: Post a comment on the GitHub issue detailing exactly what changes were made and how they were verified.
    *   **Create a Pull Request (PR/MR)**: Once the work is done and verified, create a Pull Request from the feature branch to `main`.
    *   **Squash & Cleanup**: The PR should be merged using the **Squash and Merge** method. After the merge is complete, the feature branch should be deleted.

4.  **Review & Merging**
    *   **Wait for User**: Do NOT merge the PR yourself. The USER will merge it manually unless they explicitly tell you to do so.
