#!/usr/bin/env bash
# PostToolUse hook for EnterWorktree: install project dependencies
# so agents working in worktrees don't have to reinstall manually.

set -euo pipefail

# Only act when we're actually in a worktree
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  exit 0
fi

# npm / bun / pnpm / yarn
if [[ -f "package.json" ]]; then
  if [[ -f "bun.lockb" || -f "bun.lock" ]]; then
    bun install --frozen-lockfile 2>/dev/null || bun install
  elif [[ -f "pnpm-lock.yaml" ]]; then
    pnpm install --frozen-lockfile
  elif [[ -f "yarn.lock" ]]; then
    yarn install --frozen-lockfile
  else
    npm ci 2>/dev/null || npm install
  fi
fi

# Python
if [[ -f "requirements.txt" ]]; then
  pip install -r requirements.txt -q
elif [[ -f "pyproject.toml" ]] && command -v uv &>/dev/null; then
  uv sync
elif [[ -f "Pipfile.lock" ]]; then
  pipenv install
fi

# PHP / Composer
if [[ -f "composer.json" && -f "composer.lock" ]]; then
  composer install --no-interaction --quiet
fi

# Go
if [[ -f "go.mod" ]]; then
  go mod download
fi
