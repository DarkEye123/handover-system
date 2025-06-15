# Inter-Agent Message Format

Structured format for communication between agents through the coordinator.

## Message Structure

```yaml
message_id: MSG-001
from: BE-001
to: FE-001
timestamp: 2024-01-15 14:30 UTC
priority: HIGH|MEDIUM|LOW
type: INFO|REQUEST|BLOCKER|UPDATE
subject: "Brief subject line"
body: |
  Detailed message content
  Can be multiple lines
requires_response: true|false
response_deadline: 2024-01-15 16:00 UTC (if applicable)
```

## Message Types

### INFO
General information sharing, no action required
```yaml
type: INFO
subject: "Auth endpoint updated"
body: |
  The /api/v2/auth endpoint now returns additional fields:
  - lastLogin: timestamp
  - sessionId: string
```

### REQUEST
Asking another agent for information or action
```yaml
type: REQUEST
subject: "Need user type definitions"
body: |
  Please provide TypeScript interfaces for:
  - User
  - UserProfile
  - UserSettings
requires_response: true
response_deadline: 2024-01-15 16:00 UTC
```

### BLOCKER
Critical issue preventing progress
```yaml
type: BLOCKER
subject: "Cannot proceed without database schema"
body: |
  Need final decision on user roles structure.
  Blocking: Authentication implementation
  Options considered:
  1. Simple role string
  2. Role object with permissions
requires_response: true
```

### UPDATE
Status update on previous request/blocker
```yaml
type: UPDATE
subject: "Re: MSG-001 - Database schema provided"
body: |
  Schema has been finalized and documented in:
  /docs/database-schema.md
  
  You can now proceed with authentication.
```

## Usage in Handovers

In your agent handover, add messages like this:

```markdown
## Outgoing Messages

### To: FE-001
**Message ID**: MSG-042
**Type**: BLOCKER
**Subject**: API breaking change
**Body**: Removing /api/v1/auth in favor of /api/v2/auth. Please update by tomorrow.

## Incoming Messages

### From: TEST-001
**Message ID**: MSG-041
**Type**: INFO
**Subject**: Test coverage report
**Status**: Acknowledged
```

## Coordinator Responsibilities

1. Assign unique message IDs
2. Route messages between agents
3. Track response deadlines
4. Escalate unanswered blockers
5. Maintain message history in COORDINATOR.md

## Best Practices

1. Keep subjects concise and descriptive
2. Include specific file paths and line numbers
3. For blockers, always propose solutions
4. Reference message IDs in responses
5. Update message status when acknowledged/resolved