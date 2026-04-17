#!/usr/bin/env bash
# PreToolUse hook: auto-approve git push to claude/* branches, block others.
# Receives tool input as JSON on stdin.

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
  # Auto-approve pushes on claude/ branches
  echo '{"decision": "approve", "reason": "Pushing to claude/ branch"}'
else
  # Block pushes to non-claude/ branches
  echo '{"decision": "block", "reason": "Only pushing to claude/* branches is allowed without confirmation"}'
fi
