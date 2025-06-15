# Agent Handover: [Agent ID]

Template for individual agent handovers in multi-agent system.

## TRUTHFULNESS COMMITMENT

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

## Agent Metadata

**Agent ID**: [e.g., BE-001]  
**Model**: [Opus/Sonnet/Haiku]  
**Role**: [Backend Dev/Frontend Dev/Tester/Architect]  
**Task**: [Specific task description]  
**Started**: [Timestamp]  
**Last Update**: [Timestamp]

## Dependencies

### Upstream (Waiting For)
<!-- What this agent needs from others -->
- Agent ID: [What they're providing]

### Downstream (Others Waiting)
<!-- Who needs this agent's output -->
- Agent ID: [What they need]

## Public Interface
<!-- What other agents need to know about your work -->

### API Changes
- 

### Data Structure Changes
- 

### New Files/Modules
- 

### Breaking Changes
- 

## Work Status

### Completed
- 

### In Progress
- 

### Next Steps
- 

### Blockers
- 

## Implementation Details
<!-- Private implementation notes for agent handover -->

### Files Modified
- 

### Key Decisions
- 

### Technical Context
- 

## Testing Handoff
<!-- Clear protocol for implementation → testing agent handoff -->

### Testing Status
- [ ] Ready for Testing
- [ ] Test Agent Assigned
- [ ] Tests In Progress
- [ ] Tests Complete

### Testing Requirements

#### Unit Tests Needed
<!-- Specific functions/modules to test -->
- 

#### Integration Tests Needed
<!-- Cross-component testing requirements -->
- 

#### Manual Testing Steps
<!-- Step-by-step manual verification -->
1. 

### Test Data/Setup
<!-- Any specific data or environment setup needed -->
- 

### Expected Outcomes
<!-- What success looks like -->
- 

### Known Edge Cases
<!-- Specific scenarios to test -->
- 

## Messages to Coordinator
<!-- Important information for the coordinator -->
- 

---
*Agent Status: [Active/Paused/Completed/Blocked]*