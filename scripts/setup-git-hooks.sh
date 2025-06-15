#!/bin/bash

# Git Hooks Setup Script for Handover System
# Sets up git hooks to validate and auto-commit handover updates

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HANDOVER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GIT_ROOT="$(cd "$HANDOVER_DIR/.." && git rev-parse --show-toplevel 2>/dev/null || echo "")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$GIT_ROOT" ]; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

HOOKS_DIR="$GIT_ROOT/.git/hooks"

echo "Setting up git hooks for handover validation..."

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash

# Pre-commit hook for handover validation
# Validates handover files before allowing commits

HANDOVER_SCRIPT="handovers/scripts/manage-handovers.sh"

# Check if we're committing handover files
if git diff --cached --name-only | grep -q "handovers/.*\.md$"; then
    echo "Validating handover files..."
    
    # Run validation
    if [ -f "$HANDOVER_SCRIPT" ]; then
        bash "$HANDOVER_SCRIPT" validate
        if [ $? -ne 0 ]; then
            echo ""
            echo "❌ Handover validation failed. Please fix errors before committing."
            exit 1
        fi
    fi
    
    echo "✅ Handover validation passed"
fi

exit 0
EOF

chmod +x "$HOOKS_DIR/pre-commit"
echo -e "${GREEN}✓ Created pre-commit hook${NC}"

# Create post-commit hook
cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash

# Post-commit hook for handover updates
# Auto-updates STATUS.md after handover commits

HANDOVER_SCRIPT="handovers/scripts/manage-handovers.sh"

# Check if we just committed handover files
if git diff --name-only HEAD^ HEAD 2>/dev/null | grep -q "handovers/.*\.md$"; then
    echo "Updating STATUS.md..."
    
    if [ -f "$HANDOVER_SCRIPT" ]; then
        bash "$HANDOVER_SCRIPT" update-status
        
        # If STATUS.md was updated, create an auto-commit
        if git diff --name-only | grep -q "handovers/STATUS.md"; then
            git add handovers/STATUS.md
            git commit -m "chore: auto-update STATUS.md after handover changes" --no-verify
            echo "✅ STATUS.md auto-committed"
        fi
    fi
fi

exit 0
EOF

chmod +x "$HOOKS_DIR/post-commit"
echo -e "${GREEN}✓ Created post-commit hook${NC}"

# Create commit-msg hook for handover commits
cat > "$HOOKS_DIR/commit-msg" << 'EOF'
#!/bin/bash

# Commit message hook for handover commits
# Adds metadata to handover-related commits

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Check if this is a handover-related commit
if git diff --cached --name-only | grep -q "handovers/.*\.md$"; then
    # Don't modify auto-commits or already formatted messages
    if [[ ! "$COMMIT_MSG" =~ "auto-update STATUS.md" ]] && [[ ! "$COMMIT_MSG" =~ "\[Agent:" ]]; then
        # Extract agent ID from modified files
        AGENT_ID=$(git diff --cached --name-only | grep "handovers/.*\.md$" | head -1 | xargs grep -m1 "Agent ID" 2>/dev/null | sed 's/.*: *//' | sed 's/[[:space:]]*$//')
        
        if [ -n "$AGENT_ID" ]; then
            # Append agent metadata
            echo "$COMMIT_MSG" > "$COMMIT_MSG_FILE"
            echo "" >> "$COMMIT_MSG_FILE"
            echo "[Agent: $AGENT_ID] [Time: $(date -u +%H:%M) UTC]" >> "$COMMIT_MSG_FILE"
        fi
    fi
fi

exit 0
EOF

chmod +x "$HOOKS_DIR/commit-msg"
echo -e "${GREEN}✓ Created commit-msg hook${NC}"

echo ""
echo -e "${GREEN}Git hooks setup complete!${NC}"
echo ""
echo "Hooks installed:"
echo "- pre-commit: Validates handover files before commit"
echo "- post-commit: Auto-updates STATUS.md after handover changes"
echo "- commit-msg: Adds agent metadata to handover commits"
echo ""
echo "To skip validation on a specific commit, use: git commit --no-verify"