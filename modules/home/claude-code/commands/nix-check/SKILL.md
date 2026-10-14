---
name: nix-check
description: Run nix fmt and build the current platform's flake check to validate configuration changes.
user-invocable: true
---

# Nix Check

Validate the current nix-config by formatting and building.

## Steps

1. Run `nix fmt` (nixfmt-tree over the whole repo). If it modifies any files, report which ones (`git status --short`).

2. Detect the platform and build that host's check:
   - If `uname -s` is `Darwin`, run: `nix build .#checks.aarch64-darwin.darwin --no-link`
   - If `uname -s` is `Linux`, run: `nix build .#checks.x86_64-linux.home --no-link`

   Prefer this over `nix flake check`, which also evaluates the `devShells`
   re-exported from the external nix-shells repo and so can fail for reasons
   outside this config.

3. Report results:
   - On success: confirm the build evaluated cleanly
   - On failure: show the error output and suggest a fix based on the error type:
     - **"undefined variable"** — likely a missing import or typo
     - **"infinite recursion"** — check for `rec {}` or circular option references
     - **"attribute missing"** — check option name spelling or missing module import
     - **"hash mismatch"** — run `nix flake update` or fix the `sha256`
