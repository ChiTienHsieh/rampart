# Rampart Launch Materials

## Twitter/X Thread Outline

**Thread: Introducing Rampart - Let Claude wreck it, safely**

1/ Introducing Rampart 🏰

Run Claude Code with --dangerously-skip-permissions... inside a Docker container.

All the power of autonomous Claude. None of the "oops I deleted everything" risk.

github.com/ChiTienHsieh/rampart

---

2/ The problem:

Claude Code asks for permission on EVERY file change, EVERY command.

Great for safety. Terrible for "fix all 47 TypeScript errors in this project."

---

3/ The solution:

Rampart wraps Claude in a container. Claude goes full YOLO mode inside.

Your workspace? Mounted from host.
Mistakes? `git checkout . && git clean -fd`

---

4/ Features:

- Token auto-detect (OAuth or API key)
- Python environment with `--uv`
- Ralph mode for iterative execution
- Pass any env vars with `--env`

---

5/ Ralph mode is 🔥

Claude runs in a loop, seeing its own previous work:

```bash
rampart --ralph "fix all type errors" \
  --completion-promise "ALL ERRORS FIXED"
```

It keeps going until the job is done (or max iterations hit).

---

6/ Get started:

```bash
git clone github.com/ChiTienHsieh/rampart
export PATH="$PWD/rampart/bin:$PATH"
export CLAUDE_CODE_OAUTH_TOKEN="your-token"

rampart "your dangerous task here"
```

---

7/ Works with:
- OrbStack (recommended for macOS)
- Docker Desktop
- Colima

Just need Docker + Git + a Claude token.

---

8/ Open source, Apache 2.0.

PRs welcome. Issues welcome. Feature ideas welcome.

Let Claude wreck it — safely. 🏰

---

## Blog Post Outline

### Title Options
- "Rampart: Run Claude Code Without Training Wheels"
- "Let Claude Wreck It — Safely: Introducing Rampart"
- "The Safe Way to Let Claude Go Autonomous"

### Sections

1. **The Permission Problem**
   - Claude Code's safety-first approach
   - Why it's annoying for bulk operations
   - The temptation to just add `--dangerously-skip-permissions`

2. **Enter Rampart**
   - Docker-based isolation
   - Same dangerous flag, contained blast radius
   - Git as the ultimate undo button

3. **How It Works**
   - Architecture diagram
   - Token handling (env var, not persisted)
   - Container lifecycle

4. **Key Features**
   - Token auto-detect
   - Ralph mode deep dive
   - Environment passthrough

5. **Real Use Cases**
   - Fixing all type errors in a project
   - Refactoring entire modules
   - Running unknown setup scripts

6. **Security Considerations**
   - What's protected, what's not
   - Token revocation
   - Network access (not isolated)

7. **Getting Started**
   - Installation
   - First run
   - Common flags

8. **What's Next**
   - npm profile
   - playwright profile
   - Resource limits

---

## awesome-claude-plugins Entry

```markdown
### Rampart

Run Claude Code autonomously in isolated Docker containers.

- **Repo**: https://github.com/ChiTienHsieh/rampart
- **Features**:
  - Full `--dangerously-skip-permissions` in container
  - Token auto-detect (OAuth + API key)
  - Ralph mode for iterative execution
  - Python (uv) environment support
- **Use case**: Bulk operations, risky refactors, running unknown commands
```

---

## Hacker News Title Options

- "Rampart: Run Claude Code Autonomously in Docker"
- "Show HN: Rampart – Sandboxed Autonomous Claude Code"
- "Let Claude Code go wild (in a container)"
