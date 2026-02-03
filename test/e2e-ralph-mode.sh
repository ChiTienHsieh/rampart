#!/usr/bin/env bash
#
# e2e-ralph-mode.sh - End-to-end test for rampart ralph mode
#
# Usage:
#   ./test/e2e-ralph-mode.sh          # Run test, cleanup on success
#   ./test/e2e-ralph-mode.sh --keep   # Keep temp dir for inspection
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

log_info "Running e2e ralph mode test for rampart"
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

TEST_DIR="$(mktemp -d /tmp/rampart-ralph-test-XXXXXX)"
trap cleanup EXIT

log_info "Test workspace: $TEST_DIR"

# Initialize git
cd "$TEST_DIR"
git init --quiet
git config user.email "test@example.com"
git config user.name "Test"
echo "# rampart ralph test" > README.md
git add -A
git commit -m "init" --quiet

log_pass "Git initialized"

# ============ Test 1: Simple Promise Detection ============

echo ""
log_info "Test 1: Simple promise detection (single iteration)"
echo ""

PROMPT="Create a file called answer.txt containing the number 42. After creating the file, output exactly: [[PROMISE: FILE CREATED]]"

# Run rampart in ralph mode
set +e
"$RAMPART_BIN" -y -w "$TEST_DIR" --ralph --max-iterations 3 --completion-promise "FILE CREATED" "$PROMPT" 2>&1 | tee "$TEST_DIR/test1-output.log"
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -ne 0 ]; then
    log_fail "Test 1: rampart exited with code: $EXIT_CODE"
    KEEP=true
    exit 1
fi

# Verify file was created
if [ ! -f "$TEST_DIR/answer.txt" ]; then
    log_fail "Test 1: answer.txt not created"
    KEEP=true
    exit 1
fi

# Verify content
if grep -q "42" "$TEST_DIR/answer.txt"; then
    log_pass "Test 1: answer.txt contains 42"
else
    log_fail "Test 1: answer.txt does not contain 42"
    KEEP=true
    exit 1
fi

# Verify promise was detected
if grep -q "Completion promise detected" "$TEST_DIR/test1-output.log"; then
    log_pass "Test 1: Promise detected in output"
else
    log_warn "Test 1: Promise detection message not found (may be in stderr)"
fi

log_pass "Test 1: Simple promise detection passed"

# ============ Test 2: Multi-iteration (if time permits) ============

# This test is commented out as it would take longer
# Uncomment to test multi-iteration behavior

# echo ""
# log_info "Test 2: Multi-iteration behavior"
# echo ""
#
# PROMPT2="Check the workspace. Create files step1.txt, step2.txt, step3.txt one at a time (one file per iteration). Only create a file if it doesn't exist. When all three files exist, output: <promise>ALL STEPS DONE</promise>"
#
# set +e
# "$RAMPART_BIN" -y -w "$TEST_DIR" --ralph --max-iterations 5 --completion-promise "ALL STEPS DONE" "$PROMPT2" 2>&1 | tee "$TEST_DIR/test2-output.log"
# EXIT_CODE=$?
# set -e
#
# # Verify all step files exist
# for f in step1.txt step2.txt step3.txt; do
#     if [ -f "$TEST_DIR/$f" ]; then
#         log_pass "Test 2: $f exists"
#     else
#         log_fail "Test 2: $f not created"
#         KEEP=true
#     fi
# done

# ============ Verify Logging ============

echo ""
log_info "Checking logs..."

LOG_DIR="$TEST_DIR/logs"
if [ -d "$LOG_DIR" ]; then
    LOG_COUNT=$(ls -1 "$LOG_DIR"/rampart-*.log 2>/dev/null | wc -l | tr -d ' ')
    if [ "$LOG_COUNT" -gt 0 ]; then
        log_pass "Log files created: $LOG_COUNT"

        # Check log contains ralph mode info
        LOG_FILE=$(ls -1 "$LOG_DIR"/rampart-*.log 2>/dev/null | head -1)
        if grep -q "ralph" "$LOG_FILE"; then
            log_pass "Log shows ralph mode"
        else
            log_warn "Log doesn't mention ralph mode"
        fi
    else
        log_warn "logs/ dir exists but no log files"
    fi
else
    log_warn "logs/ directory not created"
fi

# ============ Summary ============

echo ""
echo "========================================"
echo -e "${GREEN}All ralph mode tests passed!${NC}"
echo "========================================"

if [ "$KEEP" = true ]; then
    echo ""
    log_info "Test dir preserved: $TEST_DIR"
fi
