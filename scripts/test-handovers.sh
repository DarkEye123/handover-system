#!/bin/bash

# Test suite for handover management scripts
# Runs unit and integration tests

# Don't use set -e as it interferes with test counting

# Test setup
TEST_DIR="$(cd "$(dirname "$0")" && pwd)/test-tmp"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANAGE_SCRIPT="$SCRIPT_DIR/manage-handovers.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework functions
function setup_test_env() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR/handovers/active"
    mkdir -p "$TEST_DIR/handovers/completed"
    mkdir -p "$TEST_DIR/handovers/scripts"
    
    # Copy scripts and templates to test environment
    cp "$MANAGE_SCRIPT" "$TEST_DIR/handovers/scripts/"
    
    # Copy the actual AGENT_TEMPLATE.md from the parent directory
    cp "$SCRIPT_DIR/../AGENT_TEMPLATE.md" "$TEST_DIR/handovers/"

    # Set test handover dir and update script path
    export HANDOVER_DIR="$TEST_DIR/handovers"
    export PATH="$TEST_DIR/handovers/scripts:$PATH"
    cd "$TEST_DIR"
}

function teardown_test_env() {
    cd - > /dev/null
    rm -rf "$TEST_DIR"
}

function assert_equals() {
    local expected=$1
    local actual=$2
    local message=$3
    
    if [ "$expected" == "$actual" ]; then
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        return 1
    fi
}

function assert_contains() {
    local haystack=$1
    local needle=$2
    local message=$3
    
    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        echo "  String: $haystack"
        echo "  Should contain: $needle"
        return 1
    fi
}

function assert_file_exists() {
    local file=$1
    local message=$2
    
    if [ -f "$file" ]; then
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        echo "  File not found: $file"
        return 1
    fi
}

function assert_dir_exists() {
    local dir=$1
    local message=$2
    
    if [ -d "$dir" ]; then
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        echo "  Directory not found: $dir"
        return 1
    fi
}

function run_test() {
    local test_name=$1
    local test_function=$2
    
    ((TESTS_RUN++))
    echo -n "  Testing $test_name... "
    
    # Save current directory
    local orig_dir=$(pwd)
    
    # Run test with proper error handling
    setup_test_env
    if $test_function 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC}"
        ((TESTS_FAILED++))
    fi
    teardown_test_env
    
    # Restore directory
    cd "$orig_dir"
}

# Unit Tests

function test_new_task_creates_directory() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task test-task BE-001
    assert_dir_exists "$HANDOVER_DIR/active/test-task" "Task directory should be created"
}

function test_new_task_creates_handover_file() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task test-task BE-001
    assert_file_exists "$HANDOVER_DIR/active/test-task/HANDOVER.md" "HANDOVER.md should be created"
}

function test_new_task_fills_agent_id() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task test-task BE-001
    local content=$(cat "$HANDOVER_DIR/active/test-task/HANDOVER.md")
    assert_contains "$content" "BE-001" "Agent ID should be filled"
}

function test_new_task_fills_date() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task test-task BE-001
    local content=$(cat "$HANDOVER_DIR/active/test-task/HANDOVER.md")
    local today=$(date +%Y-%m-%d)
    assert_contains "$content" "$today" "Current date should be filled"
}

function test_new_task_duplicate_fails() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task test-task BE-001
    # This should fail
    if bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task test-task BE-001 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

function test_complete_task_moves_directory() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task test-task BE-001
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" complete test-task
    
    # Check source removed
    if [ -d "$HANDOVER_DIR/active/test-task" ]; then
        echo "Active directory should be removed"
        return 1
    fi
    
    # Check destination exists
    local completed_dir=$(ls "$HANDOVER_DIR/completed" | grep "test-task")
    if [ -z "$completed_dir" ]; then
        echo "Completed directory not found"
        return 1
    fi
}

function test_complete_nonexistent_task_fails() {
    if bash "$HANDOVER_DIR/scripts/manage-handovers.sh" complete nonexistent 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

function test_list_active_empty() {
    local output=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" list-active)
    assert_contains "$output" "No active tasks" "Should show no active tasks"
}

function test_list_active_with_tasks() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task task1 BE-001
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task task2 FE-001
    
    local output=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" list-active)
    assert_contains "$output" "task1" "Should list task1"
    assert_contains "$output" "task2" "Should list task2"
    assert_contains "$output" "BE-001" "Should show agent BE-001"
    assert_contains "$output" "FE-001" "Should show agent FE-001"
}

function test_list_blocked_none() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task task1 BE-001
    local output=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" list-blocked)
    assert_contains "$output" "No blocked tasks" "Should show no blocked tasks"
}

function test_list_blocked_with_blockers() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task task1 BE-001
    
    # Add blocker to handover
    local handover="$HANDOVER_DIR/active/task1/HANDOVER.md"
    sed 's/\*Agent Status: Active\*/\*Agent Status: Blocked\*/' "$handover" > "$handover.tmp" && mv "$handover.tmp" "$handover"
    
    local output=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" list-blocked)
    assert_contains "$output" "task1" "Should list blocked task"
}

function test_validate_valid_handover() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task task1 BE-001
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" validate
}

function test_validate_missing_fields() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task task1 BE-001
    
    # Remove required field
    local handover="$HANDOVER_DIR/active/task1/HANDOVER.md"
    sed '/## Work Status/d' "$handover" > "$handover.tmp" && mv "$handover.tmp" "$handover"
    
    if bash "$HANDOVER_DIR/scripts/manage-handovers.sh" validate 2>/dev/null; then
        return 1
    else
        return 0
    fi
}

function test_update_status_creates_file() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task task1 BE-001
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" update-status
    
    assert_file_exists "$HANDOVER_DIR/STATUS.md" "STATUS.md should be created"
}

function test_update_status_includes_active_tasks() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task task1 BE-001
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task task2 FE-001
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" update-status
    
    local content=$(cat "$HANDOVER_DIR/STATUS.md")
    assert_contains "$content" "BE-001" "Should include BE-001 agent"
    assert_contains "$content" "FE-001" "Should include FE-001 agent"
    assert_contains "$content" "task1" "Should include task1"
    assert_contains "$content" "task2" "Should include task2"
}

function test_new_message_generates_id() {
    local output=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-message BE-001 FE-001 INFO "Test message")
    assert_contains "$output" "MSG-001" "Should generate message ID MSG-001"
}

function test_new_message_increments_id() {
    # Create a message in MESSAGES.md
    echo "MSG-005" > "$HANDOVER_DIR/MESSAGES.md"
    
    local output=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-message BE-001 FE-001 INFO "Test")
    assert_contains "$output" "MSG-006" "Should generate next message ID"
}

function test_new_message_request_has_deadline() {
    local output=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-message BE-001 FE-001 REQUEST "Test")
    assert_contains "$output" "Response Deadline" "REQUEST should have deadline"
}

function test_new_message_blocker_high_priority() {
    local output=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-message BE-001 FE-001 BLOCKER "Test" 2>&1)
    # Just check if HIGH appears in the output (accounting for the conditional)
    if [[ "$output" == *"BLOCKER"* ]] && [[ "$output" == *"HIGH"* ]]; then
        return 0
    else
        echo "BLOCKER message should result in HIGH priority"
        return 1
    fi
}

function test_check_stale_fresh_handover() {
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task task1 BE-001
    local output=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" check-stale)
    assert_contains "$output" "All handovers are up to date" "Fresh handover should not be stale"
}

function test_portable_date_calculation() {
    # Test that date calculations work
    local output=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-message BE-001 FE-001 REQUEST "Test" 2>&1)
    
    # Check that deadline is in the output
    if [[ "$output" == *"Response Deadline:"* ]] || [[ "$output" == *"response_deadline:"* ]]; then
        # Date command worked (either GNU or Python fallback)
        return 0
    else
        echo "No deadline found in output"
        return 1
    fi
}

# Integration Tests

function test_full_task_lifecycle() {
    # Create task
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task integration-test BE-001
    
    # Verify it's in active list
    local active=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" list-active)
    assert_contains "$active" "integration-test" "Task should be in active list"
    
    # Update status
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" update-status
    assert_file_exists "$HANDOVER_DIR/STATUS.md" "STATUS.md should exist"
    
    # Complete task
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" complete integration-test
    
    # Verify it's not in active list
    local active_after=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" list-active)
    if [[ "$active_after" == *"integration-test"* ]]; then
        echo "Task should not be in active list after completion"
        return 1
    fi
}

function test_multi_agent_workflow() {
    # Create multiple tasks
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task backend-api BE-001
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task frontend-ui FE-001
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task database-schema DB-001
    
    # Block one task
    local handover="$HANDOVER_DIR/active/frontend-ui/HANDOVER.md"
    sed 's/\*Agent Status: Active\*/\*Agent Status: Blocked\*/' "$handover" > "$handover.tmp" && mv "$handover.tmp" "$handover"
    # Add a real blocker (not just "None")
    sed '/### Blockers/,/^$/s/^- *$/- Waiting for API endpoints/' "$handover" > "$handover.tmp" && mv "$handover.tmp" "$handover"
    
    # Check blocked list
    local blocked=$(bash "$HANDOVER_DIR/scripts/manage-handovers.sh" list-blocked)
    assert_contains "$blocked" "frontend-ui" "Should show blocked task"
    
    # Update status
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" update-status
    local status=$(cat "$HANDOVER_DIR/STATUS.md")
    # Only frontend-ui should be blocked
    assert_contains "$status" "FE-001 | Sonnet | frontend-ui | 🔴 Blocked" "Should show frontend-ui as blocked"
}

# Performance Tests

function test_handle_many_tasks() {
    # Create 20 tasks
    for i in {1..20}; do
        bash "$HANDOVER_DIR/scripts/manage-handovers.sh" new-task "task-$i" "AGENT-$i"
    done
    
    # Time the update-status command
    local start=$(date +%s)
    bash "$HANDOVER_DIR/scripts/manage-handovers.sh" update-status
    local end=$(date +%s)
    local duration=$((end - start))
    
    # Should complete in reasonable time (< 5 seconds)
    if [ $duration -gt 5 ]; then
        echo "update-status took too long: ${duration}s"
        return 1
    fi
    
    # Verify all tasks are in STATUS.md
    local status=$(cat "$HANDOVER_DIR/STATUS.md")
    for i in {1..20}; do
        assert_contains "$status" "AGENT-$i" "Should include AGENT-$i"
    done
}

# Main test runner

function run_all_tests() {
    echo -e "${BLUE}Running Handover Script Tests${NC}"
    echo "================================"
    
    echo -e "\n${YELLOW}Unit Tests:${NC}"
    run_test "new-task creates directory" test_new_task_creates_directory
    run_test "new-task creates handover file" test_new_task_creates_handover_file
    run_test "new-task fills agent ID" test_new_task_fills_agent_id
    run_test "new-task fills date" test_new_task_fills_date
    run_test "new-task duplicate fails" test_new_task_duplicate_fails
    run_test "complete task moves directory" test_complete_task_moves_directory
    run_test "complete nonexistent task fails" test_complete_nonexistent_task_fails
    run_test "list-active empty" test_list_active_empty
    run_test "list-active with tasks" test_list_active_with_tasks
    run_test "list-blocked none" test_list_blocked_none
    run_test "list-blocked with blockers" test_list_blocked_with_blockers
    run_test "validate valid handover" test_validate_valid_handover
    run_test "validate missing fields" test_validate_missing_fields
    run_test "update-status creates file" test_update_status_creates_file
    run_test "update-status includes tasks" test_update_status_includes_active_tasks
    run_test "new-message generates ID" test_new_message_generates_id
    run_test "new-message increments ID" test_new_message_increments_id
    run_test "new-message request deadline" test_new_message_request_has_deadline
    run_test "new-message blocker priority" test_new_message_blocker_high_priority
    run_test "check-stale fresh handover" test_check_stale_fresh_handover
    run_test "portable date calculation" test_portable_date_calculation
    
    echo -e "\n${YELLOW}Integration Tests:${NC}"
    run_test "full task lifecycle" test_full_task_lifecycle
    run_test "multi-agent workflow" test_multi_agent_workflow
    
    echo -e "\n${YELLOW}Performance Tests:${NC}"
    run_test "handle many tasks" test_handle_many_tasks
    
    echo -e "\n================================"
    echo -e "Tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    fi
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed! ✨${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed! 💥${NC}"
        exit 1
    fi
}

# Check if we're being sourced or executed
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    run_all_tests
fi