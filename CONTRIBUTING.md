# Contributing to Rampart

Thanks for your interest in contributing!

## Development Setup

```bash
git clone https://github.com/ChiTienHsieh/rampart.git
cd rampart

# Set your token
export CLAUDE_CODE_OAUTH_TOKEN="your-token"

# Build images
./bin/rampart --build "echo test"
```

## Running Tests

```bash
# Run e2e happy path test
./test/e2e-happy-path.sh

# Run ralph mode test
./test/e2e-ralph-mode.sh

# Keep temp dir for inspection
./test/e2e-happy-path.sh --keep
```

## PR Guidelines

1. **Test your changes**: Run both e2e tests before submitting
2. **Keep it focused**: One feature/fix per PR
3. **Update docs**: If adding flags or features, update README.md
4. **No yolo references**: Ensure `grep -r "yolo" .` returns empty

## Code Style

- Bash scripts: Use `set -e`, quote variables, use `[[` for conditionals
- Comments: Explain "why", not "what"
- Colors: Use the defined color variables (RED, GREEN, etc.)

## Reporting Issues

Please include:
- Rampart version (`git log -1 --oneline`)
- Docker runtime (Docker Desktop, OrbStack, Colima)
- OS version
- Full error output

## Feature Ideas

- [ ] npm profile for Node.js projects
- [ ] playwright profile for browser automation
- [ ] Resource limits (memory, CPU)
- [ ] Session persistence (continue previous session)

Feel free to pick one up or propose new ideas!
