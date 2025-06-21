# HANDOVER.md

This file is used for session handovers between Claude instances when context limits are reached.

## CRITICAL: TRUTHFULNESS REQUIREMENTS

### What I MUST Do:
- Use Read/Grep/Glob tools to verify file existence before claiming they exist
- Copy exact code snippets from files, never paraphrase or recreate from memory
- Run commands to check actual state (git status, npm list, etc.) 
- Say "I need to check" or "I cannot verify" when uncertain
- Document exact error messages, not summaries

### What I MUST NOT Do:
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

## Current Session Info

**Date**: [Session Date]
**Branch**: [Current Branch]
**Primary Task**: [What you're working on]
**Session Start Context**: [Original user request/goal]

## Work Completed

### Files Modified
<!-- List files with brief description of changes -->
- `path/to/file.ts`: [What was changed and why]

### Key Decisions & Pivots
<!-- Important architectural or implementation decisions, major strategy changes -->
- 

### Code Patterns Discovered
<!-- Useful patterns or conventions found during work -->
```typescript
// Example pattern
```

## In Progress

### Current Task
<!-- What you were doing when context limit was reached -->

### Next Steps
<!-- Specific next actions to take -->
1. 

### Blockers/Issues
<!-- Any problems that need resolution -->
- 

### Escalation Needed
<!-- Tasks that require user decision/input -->
**Task**: [What needs to be done]
**Blocker**: [Why it cannot proceed]
**Decision Needed**: [Specific question for user]

## Important Context

### Dependencies/Imports
<!-- Key dependencies or imports discovered -->
- 

### File Relationships
<!-- How files interact with each other -->
- 

### State Management
<!-- Important state/data flow to understand -->
- 

### API/Message Patterns
<!-- Extension messaging, Firebase calls, etc. -->
- 

## Testing & Validation

### Testing Notes
<!-- How to test the changes made -->
- 

### Verification Steps
<!-- What to check to ensure changes work -->
- 

### Error States Encountered
<!-- Errors seen and how they were/should be resolved -->
- 

## Commands & Environment

### Commands Run
<!-- Useful commands that were executed -->
```bash
# Example
```

### Environment State
<!-- Any environment changes made -->
- Environment mode: [test/normal]
- Firebase emulators: [on/off]

## Todo List State
<!-- Current todo items and their status -->
- [ ] Task 1
- [x] Task 2 (completed)
- [>] Task 3 (in progress)

## Questions for User
<!-- Any clarifications needed -->
- 

## Potential Pitfalls
<!-- Warnings for the next Claude instance -->
- 

## Time Tracking
**Estimated Time**: [Initial estimate]
**Actual Time Spent**: [Track actual time]
**Remaining Estimate**: [Updated estimate]

---
*Note: Clear this file when starting a new major task or after successful task completion.*
*Last Updated: [Date] [HH:MM UTC] by [Agent ID/Model]*