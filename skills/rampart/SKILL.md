---
name: rampart
description: Delegate risky autonomous tasks to a containerized Claude Code instance. Use when a task requires many file changes, running unknown commands, or would benefit from Claude operating without permission prompts - but in an isolated Docker sandbox where mistakes can be easily recovered.
allowed-tools: Bash
---

# Rampart: Containerized Claude Code Delegation

## When to Use

Delegate to rampart when:
- Task requires many autonomous file changes ("fix all type errors", "refactor entire module")
- Need to run potentially destructive commands without constant permission prompts
- Want to let Claude experiment freely but contain the blast radius
- Multi-step implementation where interruptions would break flow

Do NOT use for:
- Simple single-file edits (just do it directly)
- Tasks needing host-specific tools not available in the container

## Architecture

```
User <-> Normal CC (safe, asks permissions)
              |
              v
         rampart container
         - --dangerously-skip-permissions enabled
         - .git mounted (always recoverable)
         - workspace mounted read-write
         - Full internet access (not isolated)
         - Disk isolation only (Docker sandbox)
```

## How to Invoke

```bash
# Basic usage
rampart "your detailed prompt here"

# With Python (uv) environment
rampart --uv "create FastAPI server with SQLAlchemy models"

# Specific workspace
rampart -w /path/to/project "refactor auth module"

# Prompt from file (for long/complex prompts)
rampart -f ./plan.md

# Force rebuild images
rampart --build "update dependencies"

# Pass environment variables
rampart --env DEBUG=1 --env API_URL=http://localhost "run tests"

# Skip confirmation prompts (CI/CD friendly)
rampart -y "automated task"
```

## Requirements

- CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY env var must be set
- Docker/OrbStack running
- `rampart` is available in PATH

## Token Auto-Detection

Rampart automatically detects tokens in this priority order:
1. `CLAUDE_CODE_OAUTH_TOKEN` (OAuth token from `claude auth login`)
2. `ANTHROPIC_API_KEY` (API key from console.anthropic.com)

By default, rampart shows the detected token (masked) and asks for confirmation.
Use `-y` or `--yes` to skip the confirmation prompt.

## Important Gotchas

### Sandbox Bypass Required
When running from Claude Code in sandbox mode, you MUST use `dangerouslyDisableSandbox: true` to access OrbStack/Docker resources. The daemon check fails otherwise with "Docker daemon not running" even when OrbStack is running.

### File Visibility
**Container only sees files in the workspace directory (cwd).** Files outside the workspace are NOT accessible:
- Plan files in `~/.claude/plans/` → NOT visible
- Global configs in `~/.claude/` → NOT visible
- Other project directories → NOT visible

**Solution**: Copy any reference files (plans, configs, context docs) into the workspace before invoking rampart:
```bash
# Copy plan file to workspace first
cp ~/.claude/plans/my-plan.md ./ai_chatroom/plan.md

# Then invoke rampart with workspace-local path
rampart "Read plan at ./ai_chatroom/plan.md and implement it"
```

## Available Flags

```
--uv              Include Python (uv) environment
--npm             Include Node.js environment [TODO]
--playwright      Include Playwright [TODO]
-w, --workspace   Workspace directory (default: cwd)
--build           Force rebuild images
-f, --file PATH   Read prompt from file
--env KEY=VALUE   Pass env var to container (repeatable)
-y, --yes         Skip confirmation prompts

Ralph Mode:
--ralph                 Enable iterative execution
--max-iterations N      Max iterations (default: 10)
--completion-promise T  Promise phrase to signal completion
```

## Ralph Mode (Iterative Execution)

Ralph mode implements the [Ralph Wiggum technique](https://ghuntley.com/ralph/) - Claude runs in a loop, seeing its own previous work, until completion.

```bash
# Fix errors iteratively
rampart --ralph "fix all type errors" --completion-promise "ALL ERRORS FIXED"

# Iterative improvement with limit
rampart --ralph --max-iterations 20 "improve test coverage to 80%"
```

### How It Works

1. First iteration: Claude gets prompt via `-p`
2. Subsequent iterations: Same prompt via `--continue` (Claude sees previous conversation)
3. Exit when: `[[PROMISE: TEXT]]` detected OR max iterations reached

### Best Practices for Ralph Mode

- **Clear completion criteria**: Define what "done" means
- **Verifiable promises**: Use promises Claude can objectively verify
- **Set max iterations**: Always set a limit to prevent runaway loops
- Good: `--completion-promise "ALL TESTS PASSING"` (verifiable)
- Bad: `--completion-promise "CODE IS CLEAN"` (subjective)

## Prompt Guidelines

When delegating to rampart, write detailed prompts:
1. State the goal clearly
2. Mention specific files/directories if known
3. Include constraints or requirements
4. Request a summary of changes at the end

Example prompt:
```
Fix all TypeScript errors in src/.
Run `npm run build` to verify.
At the end, provide a summary of files changed and errors fixed.
```

## Recovery

If rampart makes unwanted changes:
```bash
cd /workspace
git checkout .      # Restore tracked files
git clean -fd       # Remove untracked files
```

## Security Notes

- Token passed via env var (not persisted in container filesystem)
- OAuth tokens only work with Claude Code, cannot be used for raw API abuse
- Can revoke OAuth token anytime at claude.ai/settings/account → Active Connections
- Container deletion clears all runtime state
