# Handover System Documentation

Complete multi-agent coordination system with automation, monitoring, and git integration.

## Which File Should I Read?

### If you are a Single Agent (no multi-agent coordination):
- **Primary**: `/HANDOVER.md` - Session handover for context switches
- **Reference**: `/CLAUDE.md` - General project guidelines

### If you are a Coordinator:
- **Primary**: `/handovers/COORDINATOR.md` - Your main instructions
- **Monitor**: `/handovers/STATUS.md` - System overview dashboard
- **Review**: `/handovers/MESSAGES.md` - Message routing and format

### If you are a Task Agent (in multi-agent system):
- **Primary**: `/handovers/active/<your-task>/HANDOVER.md` - Your specific task handover
- **Reference**: `/CLAUDE.md` - General project guidelines
- **Templates**: `/handovers/AGENT_TEMPLATE.md` - If creating new handovers

### If you are setting up the system:
- **This file**: Complete system documentation
- **Scripts**: `/handovers/scripts/` - Automation tools

## Quick Start

```bash
# Create a new task
./scripts/manage-handovers.sh new-task auth-refactor BE-001

# Generate a message ID
./scripts/manage-handovers.sh new-message BE-001 FE-001 BLOCKER "API breaking change"

# Update status dashboard
./scripts/manage-handovers.sh update-status

# Setup git hooks (one-time)
./scripts/setup-git-hooks.sh
```

## Truthfulness Framework

### What Agents MUST Do:

- Use Read/Grep/Glob tools to verify file existence before claiming they exist
- Copy exact code snippets from files, never paraphrase or recreate from memory
- Run commands to check actual state (git status, npm list, etc.)
- Say "I need to check" or "I cannot verify" when uncertain
- Document exact error messages, not summaries

### What Agents MUST NOT Do:

- Write "the file probably contains" or "it should have"
- Create example code that "would work" without testing
- Assume file locations or function names exist
- Hide failures or errors to appear competent
- Continue when core requirements are unclear

### Escalation Examples:

- "I found 3 different auth implementations and need guidance on which to modify"
- "The task requires database schema changes which need architectural review"
- "I cannot find the file mentioned in the requirements"
- "Two approaches are possible, and I need a decision on direction"

## Directory Structure

```
/
├── HANDOVER.md           # Single-agent session handover (for context switches)
├── CLAUDE.md             # General project guidelines for all agents
└── handovers/            # Multi-agent coordination system
    ├── README.md         # This file - system documentation
    ├── COORDINATOR.md    # Instructions for coordinator agents
    ├── AGENT_TEMPLATE.md # Template for creating new agent handovers
    ├── MESSAGES.md       # Message format specification and examples
    ├── STATUS.md         # Auto-generated dashboard (DO NOT EDIT)
    ├── active/           # Active task handovers
    │   └── <task-name>/
    │       └── HANDOVER.md   # Task-specific agent instructions
    ├── completed/        # Archived completed tasks
    │   └── <task-name>-YYYYMMDD/
    │       └── HANDOVER.md
    └── scripts/
        ├── manage-handovers.sh    # Main management script
        └── setup-git-hooks.sh     # Git hooks installer
```

## Features

### 1. Task Management

- **Create tasks** with pre-filled templates
- **Complete tasks** with automatic archival
- **List active/blocked** tasks
- **Validate** handover formats
- **Detect stale** handovers (>24h)

### 2. Communication System

- **Structured messages** (YAML format)
- **Auto-generated message IDs**
- **Message types**: INFO, REQUEST, BLOCKER, UPDATE
- **Response tracking** with deadlines
- **Priority levels** and routing

### 3. Status Dashboard

- **Real-time overview** of all agents
- **Visual status indicators** (🟢🟡🔴✅)
- **Task pipeline** visualization
- **Metrics tracking** (weekly stats)
- **Auto-updates** from handover files

### 4. Git Integration

- **Pre-commit validation** of handover files
- **Post-commit auto-update** of STATUS.md
- **Commit message enrichment** with agent metadata
- **Skip with**: `git commit --no-verify`

## Management Script Commands

### `new-task <name> <agent-id>`
Creates new task directory with pre-filled handover template.
```bash
./scripts/manage-handovers.sh new-task auth-refactor BE-001
```

### `complete <name>`
Archives completed task with timestamp.
```bash
./scripts/manage-handovers.sh complete auth-refactor
```

### `update-status`
Regenerates STATUS.md from all active handovers.
```bash
./scripts/manage-handovers.sh update-status
```

### `new-message <from> <to> <type> <subject>`
Generates unique message ID and template.
```bash
./scripts/manage-handovers.sh new-message BE-001 FE-001 REQUEST "Need API specs"
```

### `list-active`
Shows all active tasks with agent assignments.

### `list-blocked`
Identifies tasks with blockers needing attention.

### `check-stale`
Finds handovers not updated in 24+ hours.

### `validate`
Checks all handover files for required fields.

## Git Hooks

### Pre-commit
- Validates handover files before commit
- Ensures required fields are present
- Prevents broken handovers

### Post-commit
- Auto-updates STATUS.md after handover changes
- Creates automatic commit for dashboard updates
- Maintains synchronized state

### Commit-msg
- Adds agent metadata to commit messages
- Format: `[Agent: ID] [Time: HH:MM UTC]`
- Helps track who made changes

## Critical Rules

1. **Two-Strike Rule**: If two different agents fail on the same task, it MUST be escalated to the user
2. **Never Make Up Information**: Always verify with tools before stating facts
3. **Document Blockers**: Clearly state what's preventing progress
4. **Update Frequently**: Stale handovers break coordination
5. **Use Message IDs**: All inter-agent communication needs tracking

## Message Types

- **INFO**: General updates, no response needed
- **REQUEST**: Needs response within deadline
- **BLOCKER**: Critical issue, high priority
- **UPDATE**: Response to previous message

## Status Indicators

- 🟢 **Active**: Working normally
- 🟡 **Waiting**: Dependency blocked
- 🔴 **Blocked**: Needs escalation
- ✅ **Ready**: Testing/completion

## Troubleshooting

### Validation Errors
```bash
# Check specific requirements
./scripts/manage-handovers.sh validate

# Common fixes:
# - Add missing Agent ID
# - Include Work Status section
# - Add Public Interface section
```

### Stale Handovers
```bash
# Find outdated files
./scripts/manage-handovers.sh check-stale

# Update with current status
# Mark blockers if stuck
```

### Git Hook Issues
```bash
# Skip hooks if needed
git commit --no-verify

# Reinstall hooks
./scripts/setup-git-hooks.sh
```

## Integration Points

1. **CI/CD**: Run validation in pipelines
2. **Monitoring**: Parse STATUS.md for alerts
3. **Reporting**: Use completed/ archive for metrics
4. **Automation**: Extend manage-handovers.sh as needed
