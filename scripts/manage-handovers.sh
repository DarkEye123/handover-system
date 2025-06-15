#!/bin/bash

# Handover Management Script
# Helps manage agent handovers and maintain consistency

# Don't use set -e as it can cause issues with grep and other commands that return non-zero
# set -e

# Use environment variable if set, otherwise calculate from script location
if [ -z "$HANDOVER_DIR" ]; then
    HANDOVER_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi
ACTIVE_DIR="$HANDOVER_DIR/active"
COMPLETED_DIR="$HANDOVER_DIR/completed"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function show_help() {
    echo "Handover Management Script"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  new-task <task-name> <agent-id>              Create new task directory with handover"
    echo "  complete <task-name>                         Move task to completed"
    echo "  list-active                                  List all active tasks"
    echo "  list-blocked                                 List all blocked tasks"
    echo "  check-stale                                  Find handovers not updated in 24h"
    echo "  update-status                                Update STATUS.md from handover files"
    echo "  validate                                     Check handover files for required fields"
    echo "  new-message <from> <to> <type> <subject>     Generate new message ID and template"
    echo ""
    echo "Message Types:"
    echo "  INFO     - General information sharing"
    echo "  REQUEST  - Asking for information/action"
    echo "  BLOCKER  - Critical issue preventing progress"
    echo "  UPDATE   - Status update on previous message"
    echo ""
    echo "Examples:"
    echo "  $0 new-task auth-refactor BE-001"
    echo "  $0 complete auth-refactor"
    echo "  $0 update-status"
    echo "  $0 new-message BE-001 FE-001 BLOCKER \"API breaking change\""
}

function new_task() {
    local task_name=$1
    local agent_id=$2
    
    if [ -z "$task_name" ] || [ -z "$agent_id" ]; then
        echo -e "${RED}Error: Task name and agent ID required${NC}"
        exit 1
    fi
    
    local task_dir="$ACTIVE_DIR/$task_name"
    
    if [ -d "$task_dir" ]; then
        echo -e "${RED}Error: Task directory already exists${NC}"
        exit 1
    fi
    
    mkdir -p "$task_dir"
    cp "$HANDOVER_DIR/AGENT_TEMPLATE.md" "$task_dir/HANDOVER.md"
    
    # Pre-fill some fields (portable sed for Linux/macOS)
    # Replace all template placeholders
    sed "s/\[Agent ID\]/$agent_id/g" "$task_dir/HANDOVER.md" > "$task_dir/HANDOVER.md.tmp" && mv "$task_dir/HANDOVER.md.tmp" "$task_dir/HANDOVER.md"
    sed "s/\[e.g., BE-001\]/$agent_id/g" "$task_dir/HANDOVER.md" > "$task_dir/HANDOVER.md.tmp" && mv "$task_dir/HANDOVER.md.tmp" "$task_dir/HANDOVER.md"
    sed "s/\[Timestamp\]/$(date +%Y-%m-%d) $(date -u +%H:%M) UTC/g" "$task_dir/HANDOVER.md" > "$task_dir/HANDOVER.md.tmp" && mv "$task_dir/HANDOVER.md.tmp" "$task_dir/HANDOVER.md"
    sed "s/\[Specific task description\]/$task_name/g" "$task_dir/HANDOVER.md" > "$task_dir/HANDOVER.md.tmp" && mv "$task_dir/HANDOVER.md.tmp" "$task_dir/HANDOVER.md"
    sed "s/\[Opus\/Sonnet\/Haiku\]/Sonnet/g" "$task_dir/HANDOVER.md" > "$task_dir/HANDOVER.md.tmp" && mv "$task_dir/HANDOVER.md.tmp" "$task_dir/HANDOVER.md"
    sed "s/\*Agent Status:.*\*/\*Agent Status: Active\*/" "$task_dir/HANDOVER.md" > "$task_dir/HANDOVER.md.tmp" && mv "$task_dir/HANDOVER.md.tmp" "$task_dir/HANDOVER.md"
    
    echo -e "${GREEN}Created task: $task_name for agent: $agent_id${NC}"
    echo "Handover file: $task_dir/HANDOVER.md"
}

function complete_task() {
    local task_name=$1
    
    if [ -z "$task_name" ]; then
        echo -e "${RED}Error: Task name required${NC}"
        exit 1
    fi
    
    local src_dir="$ACTIVE_DIR/$task_name"
    local dest_dir="$COMPLETED_DIR/$task_name-$(date +%Y%m%d)"
    
    if [ ! -d "$src_dir" ]; then
        echo -e "${RED}Error: Task not found in active directory${NC}"
        exit 1
    fi
    
    mv "$src_dir" "$dest_dir"
    echo -e "${GREEN}Moved $task_name to completed${NC}"
    echo "Archived at: $dest_dir"
}

function list_active() {
    echo "Active Tasks:"
    echo "============="
    
    if [ ! -d "$ACTIVE_DIR" ] || [ -z "$(ls -A "$ACTIVE_DIR" 2>/dev/null)" ]; then
        echo "No active tasks"
        return
    fi
    
    for task_dir in "$ACTIVE_DIR"/*; do
        if [ -d "$task_dir" ]; then
            task_name=$(basename "$task_dir")
            if [ -f "$task_dir/HANDOVER.md" ]; then
                agent_id=$(grep -m1 "\*\*Agent ID\*\*:" "$task_dir/HANDOVER.md" | sed 's/.*: //')
                status=$(grep -m1 "Agent Status:" "$task_dir/HANDOVER.md" | sed 's/.*: //')
                echo "- $task_name (Agent: $agent_id, Status: $status)"
            else
                echo "- $task_name (No handover file)"
            fi
        fi
    done
}

function list_blocked() {
    echo "Blocked Tasks:"
    echo "=============="
    
    local found_blocked=false
    
    if [ -d "$ACTIVE_DIR" ]; then
        for task_dir in "$ACTIVE_DIR"/*; do
            if [ -d "$task_dir" ] && [ -f "$task_dir/HANDOVER.md" ]; then
                if grep -q "Agent Status:.*Blocked" "$task_dir/HANDOVER.md"; then
                    task_name=$(basename "$task_dir")
                    agent_id=$(grep -m1 "Agent ID.*:" "$task_dir/HANDOVER.md" | sed 's/.*: //')
                    echo -e "${RED}- $task_name (Agent: $agent_id)${NC}"
                    found_blocked=true
                fi
            fi
        done
    fi
    
    if [ "$found_blocked" = false ]; then
        echo -e "${GREEN}No blocked tasks${NC}"
    fi
}

function check_stale() {
    echo "Checking for stale handovers (>24h):"
    echo "===================================="
    
    local found_stale=false
    local current_time=$(date +%s)
    
    # Check root handover
    if [ -f "$HANDOVER_DIR/../HANDOVER.md" ]; then
        local mod_time=$(stat -c %Y "$HANDOVER_DIR/../HANDOVER.md" 2>/dev/null || stat -f %m "$HANDOVER_DIR/../HANDOVER.md" 2>/dev/null || date +%s)
        local age_hours=$(( (current_time - mod_time) / 3600 ))
        
        if [ $age_hours -gt 24 ]; then
            echo -e "${YELLOW}- Root HANDOVER.md (${age_hours}h old)${NC}"
            found_stale=true
        fi
    fi
    
    # Check active task handovers
    if [ -d "$ACTIVE_DIR" ]; then
        for handover in "$ACTIVE_DIR"/*/HANDOVER.md; do
            if [ -f "$handover" ]; then
                local mod_time=$(stat -c %Y "$handover" 2>/dev/null || stat -f %m "$handover" 2>/dev/null || date +%s)
                local age_hours=$(( (current_time - mod_time) / 3600 ))
                
                if [ $age_hours -gt 24 ]; then
                    task_name=$(basename "$(dirname "$handover")")
                    echo -e "${YELLOW}- $task_name (${age_hours}h old)${NC}"
                    found_stale=true
                fi
            fi
        done
    fi
    
    if [ "$found_stale" = false ]; then
        echo -e "${GREEN}All handovers are up to date${NC}"
    fi
}

function validate() {
    echo "Validating handover files:"
    echo "========================="
    
    local errors=0
    
    # Required fields to check
    local required_fields=(
        "\*\*Agent ID\*\*:"
        "\*\*Model\*\*:"
        "\*\*Task\*\*:"
        "## Work Status"
        "## Public Interface"
    )
    
    if [ -d "$ACTIVE_DIR" ]; then
        for handover in "$ACTIVE_DIR"/*/HANDOVER.md; do
            if [ -f "$handover" ]; then
                task_name=$(basename "$(dirname "$handover")")
                echo -n "Checking $task_name... "
                
                local missing=""
                for field in "${required_fields[@]}"; do
                    if ! grep -q "$field" "$handover"; then
                        missing="$missing, $field"
                        ((errors++))
                    fi
                done
                
                if [ -z "$missing" ]; then
                    echo -e "${GREEN}OK${NC}"
                else
                    echo -e "${RED}Missing: ${missing:2}${NC}"
                fi
            fi
        done
    fi
    
    if [ $errors -eq 0 ]; then
        echo -e "\n${GREEN}All validations passed${NC}"
        return 0
    else
        echo -e "\n${RED}Found $errors validation errors${NC}"
        return 1
    fi
}

function update_status() {
    echo "Updating STATUS.md from handover files..."
    
    local status_file="$HANDOVER_DIR/STATUS.md"
    local temp_file="$status_file.tmp"
    
    # Start building the new STATUS.md
    cat > "$temp_file" << 'EOF'
# Agent Status Dashboard

Quick overview of all active agents and tasks. Check individual handover files for details.

EOF
    
    echo "*Last Updated: $(date +%Y-%m-%d) $(date -u +%H:%M) UTC*" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Active Agents Summary
    echo "## Active Agents Summary" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "| Agent ID | Model | Task | Status | Blocker | Time Active | Worktree |" >> "$temp_file"
    echo "|----------|-------|------|---------|---------|-------------|----------|" >> "$temp_file"
    
    local active_count=0
    local blocked_count=0
    local testing_count=0
    
    if [ -d "$ACTIVE_DIR" ]; then
        for task_dir in "$ACTIVE_DIR"/*; do
            if [ -d "$task_dir" ] && [ -f "$task_dir/HANDOVER.md" ]; then
                local handover="$task_dir/HANDOVER.md"
                local task_name=$(basename "$task_dir")
                
                # Extract fields from handover
                local agent_id=$(grep -m1 "\*\*Agent ID\*\*:" "$handover" | sed 's/.*: *//' | sed 's/[[:space:]]*$//')
                local model=$(grep -m1 "\*\*Model\*\*:" "$handover" | sed 's/.*: *//' | sed 's/[[:space:]]*$//')
                local task=$(grep -m1 "\*\*Task\*\*:" "$handover" | sed 's/.*: *//' | sed 's/[[:space:]]*$//')
                local status=$(grep -m1 "\*Agent Status:" "$handover" | sed 's/.*: *//' | sed 's/[[:space:]]*$//' | sed 's/\*//g')
                local started=$(grep -m1 "\*\*Started\*\*:" "$handover" | sed 's/.*: *//' | sed 's/[[:space:]]*$//')
                
                # Check for blockers - must have non-empty blocker items
                local blocker="-"
                if grep -q "### Blockers" "$handover" && grep -A5 "### Blockers" "$handover" | grep -q "^- [^[:space:]]"; then
                    blocker="Yes"
                    ((blocked_count++))
                fi
                
                # Calculate time active
                local time_active="-"
                if [ -n "$started" ]; then
                    local start_time=$(stat -c %Y "$handover" 2>/dev/null || stat -f %m "$handover" 2>/dev/null || date +%s)
                    local current_time=$(date +%s)
                    local hours=$(( (current_time - start_time) / 3600 ))
                    time_active="${hours}h"
                fi
                
                # Status emoji
                local status_icon="🟢"
                case "$status" in
                    *Blocked*) status_icon="🔴" ;;
                    *Waiting*|*Paused*) status_icon="🟡" ;;
                    *Ready*|*Testing*) status_icon="✅"; ((testing_count++)) ;;
                esac
                
                echo "| $agent_id | $model | $task | $status_icon $status | $blocker | $time_active | $task_name |" >> "$temp_file"
                ((active_count++))
            fi
        done
    fi
    
    if [ $active_count -eq 0 ]; then
        echo "| - | - | - | - | - | - | - |" >> "$temp_file"
    fi
    
    # Status Legend
    cat >> "$temp_file" << 'EOF'

## Status Legend
- 🟢 **Active**: Working normally
- 🟡 **Waiting**: Blocked by dependency
- 🔴 **Blocked**: Needs escalation
- ⏸️ **Paused**: Temporarily on hold
- ✅ **Ready for Testing**: Implementation complete

## Task Pipeline

```
📋 Backlog → 🚀 In Progress → 🧪 Testing → ✅ Complete
```

EOF
    
    # In Progress section
    echo "### In Progress ($active_count)" >> "$temp_file"
    if [ $active_count -gt 0 ] && [ -d "$ACTIVE_DIR" ]; then
        for task_dir in "$ACTIVE_DIR"/*; do
            if [ -d "$task_dir" ] && [ -f "$task_dir/HANDOVER.md" ]; then
                local task_name=$(basename "$task_dir")
                local agent_id=$(grep -m1 "\*\*Agent ID\*\*:" "$task_dir/HANDOVER.md" | sed 's/.*: *//')
                echo "- $task_name (Agent: $agent_id)" >> "$temp_file"
            fi
        done
    else
        echo "- None" >> "$temp_file"
    fi
    echo "" >> "$temp_file"
    
    # Ready for Testing section
    echo "### Ready for Testing ($testing_count)" >> "$temp_file"
    if [ $testing_count -gt 0 ]; then
        for task_dir in "$ACTIVE_DIR"/*; do
            if [ -d "$task_dir" ] && [ -f "$task_dir/HANDOVER.md" ]; then
                if grep -q "Ready for Testing" "$task_dir/HANDOVER.md"; then
                    local task_name=$(basename "$task_dir")
                    echo "- $task_name" >> "$temp_file"
                fi
            fi
        done
    else
        echo "- None" >> "$temp_file"
    fi
    echo "" >> "$temp_file"
    
    # Blocked section
    echo "### Blocked/Escalated ($blocked_count)" >> "$temp_file"
    if [ $blocked_count -gt 0 ]; then
        for task_dir in "$ACTIVE_DIR"/*; do
            if [ -d "$task_dir" ] && [ -f "$task_dir/HANDOVER.md" ]; then
                if grep -q "### Blockers" "$task_dir/HANDOVER.md" && grep -A5 "### Blockers" "$task_dir/HANDOVER.md" | grep -q "^- [^[:space:]]"; then
                    local task_name=$(basename "$task_dir")
                    local blocker_desc=$(grep -A1 "### Blockers" "$task_dir/HANDOVER.md" | tail -1 | sed 's/^- *//')
                    echo "- $task_name: $blocker_desc" >> "$temp_file"
                fi
            fi
        done
    else
        echo "- None" >> "$temp_file"
    fi
    echo "" >> "$temp_file"
    
    # Recent Completions
    echo "## Recent Completions" >> "$temp_file"
    echo "| Task | Agent ID | Completed | Duration |" >> "$temp_file"
    echo "|------|----------|-----------|----------|" >> "$temp_file"
    
    local found_completed=false
    if [ -d "$COMPLETED_DIR" ]; then
        # Get last 5 completed tasks
        for completed_dir in $(ls -t "$COMPLETED_DIR" 2>/dev/null | head -5); do
            if [ -d "$COMPLETED_DIR/$completed_dir" ] && [ -f "$COMPLETED_DIR/$completed_dir/HANDOVER.md" ]; then
                local handover="$COMPLETED_DIR/$completed_dir/HANDOVER.md"
                local task_name=$(echo "$completed_dir" | sed 's/-[0-9]\{8\}$//')
                local agent_id=$(grep -m1 "\*\*Agent ID\*\*:" "$handover" | sed 's/.*: *//')
                local completed_date=$(echo "$completed_dir" | grep -o '[0-9]\{8\}$' | sed 's/\(....\)\(..\)\(..\)/\1-\2-\3/')
                echo "| $task_name | $agent_id | $completed_date | - |" >> "$temp_file"
                found_completed=true
            fi
        done
    fi
    
    if [ "$found_completed" = false ]; then
        echo "| - | - | - | - |" >> "$temp_file"
    fi
    
    # Metrics
    echo "" >> "$temp_file"
    echo "## Metrics This Week" >> "$temp_file"
    
    # Count completions this week using portable date calculation
    local week_completions=0
    if [ -d "$COMPLETED_DIR" ]; then
        # Calculate date 7 days ago (portable solution)
        local week_ago=$(date -d '7 days ago' +%Y%m%d 2>/dev/null || python3 -c "import datetime; print((datetime.datetime.now() - datetime.timedelta(days=7)).strftime('%Y%m%d'))")
        for completed_dir in "$COMPLETED_DIR"/*; do
            if [ -d "$completed_dir" ]; then
                local dir_date=$(echo "$completed_dir" | grep -o '[0-9]\{8\}$')
                if [ -n "$dir_date" ] && [ "$dir_date" -ge "$week_ago" ]; then
                    ((week_completions++))
                fi
            fi
        done
    fi
    
    echo "- Tasks Completed: $week_completions" >> "$temp_file"
    echo "- Average Duration: -" >> "$temp_file"
    echo "- Blockers Encountered: $blocked_count" >> "$temp_file"
    echo "- Escalations to User: 0" >> "$temp_file"
    
    # Move temp file to actual file
    mv "$temp_file" "$status_file"
    echo -e "${GREEN}STATUS.md updated successfully${NC}"
}

function new_message() {
    local from_agent=$1
    local to_agent=$2
    local type=$3
    local subject=$4
    
    if [ -z "$from_agent" ] || [ -z "$to_agent" ] || [ -z "$type" ] || [ -z "$subject" ]; then
        echo -e "${RED}Error: Usage: $0 new-message <from-agent> <to-agent> <type> <subject>${NC}"
        echo "Types: INFO, REQUEST, BLOCKER, UPDATE"
        exit 1
    fi
    
    # Validate type
    case "$type" in
        INFO|REQUEST|BLOCKER|UPDATE) ;;
        *)
            echo -e "${RED}Error: Invalid type. Must be: INFO, REQUEST, BLOCKER, or UPDATE${NC}"
            exit 1
            ;;
    esac
    
    # Generate next message ID
    local last_msg_id=0
    if [ -f "$HANDOVER_DIR/MESSAGES.md" ]; then
        last_msg_id=$(grep -o "MSG-[0-9]\+" "$HANDOVER_DIR/MESSAGES.md" | sed 's/MSG-//' | sort -n | tail -1)
    fi
    if [ -d "$ACTIVE_DIR" ]; then
        local active_msg_id=$(grep -r "Message ID.*MSG-[0-9]\+" "$ACTIVE_DIR" 2>/dev/null | grep -o "MSG-[0-9]\+" | sed 's/MSG-//' | sort -n | tail -1)
        if [ -n "$active_msg_id" ] && [ "$active_msg_id" -gt "$last_msg_id" ]; then
            last_msg_id=$active_msg_id
        fi
    fi
    
    local new_msg_id=$((last_msg_id + 1))
    local msg_id=$(printf "MSG-%03d" "$new_msg_id")
    
    # Generate timestamp
    local timestamp=$(date -u +"%Y-%m-%d %H:%M UTC")
    
    # Output the message template
    echo -e "${GREEN}Generated message ID: $msg_id${NC}"
    echo ""
    echo "Add this to your handover file under '## Outgoing Messages':"
    echo ""
    echo "### To: $to_agent"
    echo "**Message ID**: $msg_id"
    echo "**Type**: $type"
    echo "**Subject**: $subject"
    echo "**Timestamp**: $timestamp"
    echo "**Body**: "
    echo "  [Add your detailed message here]"
    if [ "$type" = "REQUEST" ] || [ "$type" = "BLOCKER" ]; then
        echo "**Requires Response**: true"
        if [ "$type" = "REQUEST" ]; then
            # Calculate deadline 4 hours from now (portable solution)
            local deadline=$(date -u -d '+4 hours' +"%Y-%m-%d %H:%M UTC" 2>/dev/null || python3 -c "import datetime; print((datetime.datetime.utcnow() + datetime.timedelta(hours=4)).strftime('%Y-%m-%d %H:%M UTC'))")
            echo "**Response Deadline**: $deadline"
        fi
    fi
    echo ""
    echo "Full YAML format:"
    echo '```yaml'
    echo "message_id: $msg_id"
    echo "from: $from_agent"
    echo "to: $to_agent"
    echo "timestamp: $timestamp"
    echo "priority: $([ "$type" = "BLOCKER" ] && echo "HIGH" || echo "MEDIUM")"
    echo "type: $type"
    echo "subject: \"$subject\""
    echo "body: |"
    echo "  [Add your detailed message here]"
    if [ "$type" = "REQUEST" ] || [ "$type" = "BLOCKER" ]; then
        echo "requires_response: true"
        if [ "$type" = "REQUEST" ]; then
            # Calculate deadline 4 hours from now (portable solution)
            local deadline=$(date -u -d '+4 hours' +"%Y-%m-%d %H:%M UTC" 2>/dev/null || python3 -c "import datetime; print((datetime.datetime.utcnow() + datetime.timedelta(hours=4)).strftime('%Y-%m-%d %H:%M UTC'))")
            echo "response_deadline: $deadline"
        fi
    else
        echo "requires_response: false"
    fi
    echo '```'
}

# Main command handling
case "$1" in
    new-task)
        new_task "$2" "$3"
        ;;
    complete)
        complete_task "$2"
        ;;
    list-active)
        list_active
        ;;
    list-blocked)
        list_blocked
        ;;
    check-stale)
        check_stale
        ;;
    validate)
        validate
        ;;
    update-status)
        update_status
        ;;
    new-message)
        new_message "$2" "$3" "$4" "$5"
        ;;
    *)
        show_help
        ;;
esac