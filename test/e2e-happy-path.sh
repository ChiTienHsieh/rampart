#!/usr/bin/env bash
#
# e2e-happy-path.sh - End-to-end test for rampart
#
# Usage:
#   ./test/e2e-happy-path.sh          # Run test, cleanup on success
#   ./test/e2e-happy-path.sh --keep   # Keep temp dir for inspection
#

set -e

# ============ Config ============

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAMPART_BIN="$(dirname "$SCRIPT_DIR")/bin/rampart"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============ Helpers ============

log_info() { echo -e "[test] $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

cleanup() {
    if [ "$KEEP" = true ]; then
        log_warn "Keeping temp dir: $TEST_DIR"
    elif [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        log_info "Cleaned up: $TEST_DIR"
    fi
}

# ============ Parse Args ============

KEEP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --keep)
            KEEP=true
            shift
            ;;
        *)
            echo "Unknown flag: $1"
            exit 1
            ;;
    esac
done

# ============ Pre-flight Checks ============

log_info "Running e2e happy path test for rampart"
echo ""

# Check rampart exists
if [ ! -f "$RAMPART_BIN" ]; then
    log_fail "rampart not found at: $RAMPART_BIN"
    exit 1
fi

# Check token (either CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY)
if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
    log_fail "No token set (CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY)"
    exit 1
fi

# Check docker
if ! docker info &> /dev/null; then
    log_fail "Docker daemon not running"
    exit 1
fi

log_pass "Pre-flight checks"

# ============ Setup Test Workspace ============

TEST_DIR="$(mktemp -d /tmp/rampart-test-XXXXXX)"
trap cleanup EXIT

log_info "Test workspace: $TEST_DIR"

# Initialize git
cd "$TEST_DIR"
git init --quiet
git config user.email "test@example.com"
git config user.name "Test"
echo "# rampart test" > README.md
git add -A
git commit -m "init" --quiet

log_pass "Git initialized"

# ============ Run rampart ============

PROMPT="Calculate 13 * 14, write the result to result.txt, then print 'Done: <result>' to confirm."

log_info "Running rampart with math prompt..."
echo ""

# Run rampart (allow failure, we'll check result)
set +e
"$RAMPART_BIN" -y -w "$TEST_DIR" "$PROMPT"
EXIT_CODE=$?
set -e

echo ""

if [ $EXIT_CODE -ne 0 ]; then
    log_fail "rampart exited with code: $EXIT_CODE"
    KEEP=true  # Keep for debugging
    exit 1
fi

log_pass "rampart completed"

# ============ Verify Result ============

RESULT_FILE="$TEST_DIR/result.txt"

if [ ! -f "$RESULT_FILE" ]; then
    log_fail "result.txt not created"
    log_info "Files in test dir:"
    ls -la "$TEST_DIR"
    KEEP=true
    exit 1
fi

log_pass "result.txt exists"

# Check content contains 182
CONTENT="$(cat "$RESULT_FILE")"
if echo "$CONTENT" | grep -q "182"; then
    log_pass "result.txt contains 182"
else
    log_fail "result.txt does not contain 182"
    log_info "Actual content: $CONTENT"
    KEEP=true
    exit 1
fi

# ============ Verify Logging ============

LOG_DIR="$TEST_DIR/logs"
if [ -d "$LOG_DIR" ]; then
    LOG_COUNT=$(ls -1 "$LOG_DIR"/rampart-*.log 2>/dev/null | wc -l)
    if [ "$LOG_COUNT" -gt 0 ]; then
        log_pass "Log file created in logs/"
    else
        log_warn "logs/ dir exists but no log files"
    fi
else
    log_warn "logs/ directory not created"
fi

# Check .gitignore
if [ -f "$TEST_DIR/.gitignore" ] && grep -q "^logs/$" "$TEST_DIR/.gitignore"; then
    log_pass "logs/ added to .gitignore"
else
    log_warn "logs/ not in .gitignore"
fi

# Check container output captured in log
LOG_FILE=$(ls -1 "$LOG_DIR"/rampart-*.log 2>/dev/null | head -1)
if [ -n "$LOG_FILE" ] && grep -q "Done.*182" "$LOG_FILE"; then
    log_pass "Container output captured in log"
else
    log_warn "Container output not captured (may be expected if CC didn't print)"
fi

# ============ Summary ============

echo ""
echo "========================================"
echo -e "${GREEN}All tests passed!${NC}"
echo "========================================"

if [ "$KEEP" = true ]; then
    echo ""
    log_info "Test dir preserved: $TEST_DIR"
fi
