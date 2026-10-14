#!/usr/bin/env bash
# PreToolUse hook: auto-approve git push to claude/* branches, ask for others.
# Exit 0 = approve, exit 2 = block. JSON output for "ask".

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only act on Bash tool calls that are git push commands
if [ "$TOOL_NAME" != "Bash" ] || [[ "$COMMAND" != git\ push* ]]; then
  exit 0
fi

# Get the current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [[ "$BRANCH" == claude/* ]]; then
  exit 0
fi

# Ask for confirmation on non-claude/ branches
echo '{"hookSpecificOutput": {"permissionDecision": "ask", "reason": "Pushing to non-claude/ branch: '"$BRANCH"'"}}'
exit 0
