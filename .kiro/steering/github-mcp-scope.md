---
inclusion: always
---
# GitHub MCP Tool Scope

Only use the following GitHub MCP tools for this project:

- `create_repository` — for initial remote repo creation
- `create_pull_request` — for opening pull requests

All other Git operations (branching, staging, committing, pushing) should use the `git` CLI via bash. Do not use any other GitHub MCP tools unless the user explicitly requests it.
