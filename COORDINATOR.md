# COORDINATOR.md

Central coordination file for multi-agent system. The coordinator agent maintains this file.

## CRITICAL RULES - TRUTH AND ESCALATION

1. **NEVER make up information** - If you don't know, say so
2. **NEVER simulate or imagine** - Only report actual findings and real code
3. **ESCALATE when stuck** - If a task is too complex or needs more info, escalate immediately
4. **TWO-STRIKE RULE** - If two different agents fail on the same task, it MUST be escalated to the user
5. **BE EXPLICIT about limitations** - State clearly what you cannot do or understand

### Escalation Triggers
- Missing critical information
- Architectural decisions needed
- Security-sensitive changes
- Conflicting requirements
- Two agents blocked on same issue

## Active Agents

| Agent ID | Model | Task | Status | Last Update | Handover Location |
|----------|-------|------|---------|-------------|-------------------|
| EXAMPLE-001 | Sonnet | Backend API refactor | In Progress | 2024-01-15 10:30 | `/handovers/active/backend-api/` |

## Task Dependencies

<!-- Visual representation of dependencies between agents -->
```
BE-001 (Backend Auth) → TEST-001 (Auth Tests)
                     ↘
                       FE-001 (Frontend Integration)
```

## Inter-Agent Communication

### Pending Messages
<!-- Messages that need to be delivered to specific agents -->

#### To: [Agent ID]
**From**: [Agent ID]  
**Priority**: High/Medium/Low  
**Message**: 
- 

### Completed Handoffs
<!-- Record of successful information transfers -->
- [Date/Time] BE-001 → FE-001: Auth endpoint specification

## Blocking Issues

| Agent ID | Blocked By | Reason | Since | Escalation Status |
|----------|------------|---------|--------|-------------------|
| EXAMPLE | - | - | - | - |

### Escalation Queue
<!-- Tasks that need user review/decision -->

| Task | Agent(s) Failed | Issue | Needs Decision On | Priority |
|------|-----------------|--------|-------------------|----------|
| - | - | - | - | - |

## Global State

### Worktree Management
<!-- Track active git worktrees for parallel development -->
| Worktree | Branch | Agent ID | Purpose |
|----------|---------|----------|----------|
| - | - | - | - |

### Shared Resources
<!-- Resources multiple agents need to be aware of -->
- Firebase emulators: [running/stopped]
- Environment mode: [test/normal]

### Critical Decisions
<!-- Decisions that affect multiple agents -->
- 

## Task Allocation Guidelines

### Available for Assignment
<!-- Tasks ready to be picked up by new agents -->
1. 

### Task Complexity Estimates
<!-- Help coordinator assign appropriate model -->
- Simple tasks (Haiku suitable): File moves, simple edits
- Medium tasks (Sonnet suitable): Feature implementation, debugging  
- Complex tasks (Opus suitable): Architecture design, complex refactoring

---
*Updated by: [Coordinator Agent ID] at [Timestamp]*