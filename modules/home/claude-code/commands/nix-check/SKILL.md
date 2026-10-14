---
name: nix-check
description: Run nixfmt and nix build dry-run to validate configuration changes.
user-invocable: true
---

# Nix Check

Validate the current nix-config by formatting and building.

## Steps

1. Find changed `.nix` files:
   ```
   git diff --name-only HEAD && git diff --name-only --cached && git ls-files --others --exclude-standard '*.nix'
   ```

2. If there are changed `.nix` files, run `nixfmt` on them. If `nixfmt` modifies any files, report which files were reformatted.

3. Detect the platform:
   - If `uname -s` is `Darwin`, run: `nix build .#darwinConfigurations.jonas-mac.system --dry-run`
   - If `uname -s` is `Linux`, run: `nix build .#homeConfigurations.jonas --dry-run`

4. Report results:
   - On success: confirm the build evaluated cleanly
   - On failure: show the error output and suggest a fix based on the error type:
     - **"undefined variable"** — likely a missing import or typo
     - **"infinite recursion"** — check for `rec {}` or circular option references
     - **"attribute missing"** — check option name spelling or missing module import
     - **"hash mismatch"** — run `nix flake update` or fix the `sha256`
