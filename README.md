# Rampart

**Let Claude wreck it — safely**

Run [Claude Code](https://claude.ai/code) autonomously in isolated Docker containers. Get the power of `--dangerously-skip-permissions` without the risk.

## What is Rampart?

Rampart wraps Claude Code in a Docker container, giving Claude full autonomy to:
- Execute any bash commands
- Install packages
- Modify any files in the workspace

All changes are safely isolated. If something goes wrong: `git checkout . && git clean -fd`

## Quick Start

```bash
# Clone the repo
git clone https://github.com/ChiTienHsieh/rampart.git
cd rampart

# Add to PATH (add to ~/.bashrc or ~/.zshrc for persistence)
export PATH="$PWD/bin:$PATH"

# Set your token
export CLAUDE_CODE_OAUTH_TOKEN="your-token"  # or ANTHROPIC_API_KEY

# Run it
rampart "fix all TypeScript errors in this project"
```

## Usage

```bash
# Basic usage
rampart "your prompt here"

# With Python (uv) environment
rampart --uv "create a FastAPI server with SQLAlchemy"

# Custom workspace
rampart -w ~/projects/myapp "refactor the auth module"

# Pass environment variables to container
rampart --env DEBUG=1 --env API_URL=http://localhost:3000 "run tests"

# Skip confirmation prompts (CI/CD friendly)
rampart -y "automated task"

# Interactive shell for debugging
rampart --shell
```

### Ralph Mode (Iterative Execution)

For complex tasks that need multiple iterations:

```bash
# Basic ralph mode
rampart --ralph "fix all type errors" --completion-promise "ALL ERRORS FIXED"

# With custom iteration limit
rampart --ralph --max-iterations 20 "improve test coverage to 80%"
```

Ralph mode runs Claude in a loop, continuing until:
- The completion promise is detected in output
- Max iterations reached (default: 10)

## Token Setup

Rampart supports two authentication methods:

### Option 1: OAuth Token (Recommended)

```bash
# Get token via Claude CLI
claude auth login

# Export the token
export CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-..."
```

OAuth tokens can be revoked at [claude.ai/settings](https://claude.ai/settings) if compromised.

### Option 2: API Key

```bash
export ANTHROPIC_API_KEY="sk-ant-api..."
```

Get your API key from [console.anthropic.com](https://console.anthropic.com).

## Recovery

If Claude makes unwanted changes:

```bash
# Discard all changes
git checkout . && git clean -fd

# Or selectively restore
git diff                    # Review changes
git checkout -- file.ts     # Restore specific file
```

## Runtime Alternatives

Rampart uses Docker by default. Tested with:

- **[OrbStack](https://orbstack.dev)** (recommended for macOS) - Fast, lightweight Docker runtime
- **Docker Desktop** - Standard Docker runtime
- **Colima** - Open source Docker runtime for macOS

## How It Works

1. Mounts your workspace into a Docker container
2. Passes your Claude token via environment variable (not persisted)
3. Runs Claude Code with `--dangerously-skip-permissions`
4. Container is destroyed after execution

The container has:
- Full internet access
- Read-write access to workspace
- Isolated `node_modules` and `.venv` (container-only volumes)

## Flags Reference

| Flag | Description |
|------|-------------|
| `--uv` | Include Python (uv) environment |
| `-w, --workspace PATH` | Workspace directory (default: current dir) |
| `--build` | Force rebuild images |
| `--shell` | Open interactive shell |
| `--env KEY=VALUE` | Pass env var to container (repeatable) |
| `-y, --yes` | Skip confirmation prompts |
| `-v, --verbose` | Show debug output |
| `--ralph` | Enable ralph loop mode |
| `--max-iterations N` | Max iterations for ralph mode (default: 10) |
| `--completion-promise TEXT` | Promise phrase to signal completion |

## Requirements

- Docker (or OrbStack, Colima)
- Git (workspace must be a git repo for recovery)
- Claude Code OAuth token or Anthropic API key

## Security Considerations

- **Token exposure**: Token exists only in container memory at runtime
- **Prompt injection**: Malicious prompts could attempt to exfiltrate the token
- **Mitigation**: OAuth tokens can be revoked; use project-scoped API keys when possible
- **Recovery**: Git history provides complete rollback capability

## License

Apache 2.0
