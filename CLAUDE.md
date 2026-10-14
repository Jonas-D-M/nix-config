# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Declarative macOS + Linux environment managed with Nix Flakes, Home Manager, and nix-darwin. Supports both Linux (Pop!\_OS, x86_64) and macOS (Apple Silicon) from a single flake.

## Build & Apply Commands

| Action           | Command                                             | Alias |
| ---------------- | --------------------------------------------------- | ----- |
| Apply (macOS)    | `sudo darwin-rebuild switch --flake ~/nix-config`   | `drb` |
| Apply (Linux)    | `home-manager switch --flake ~/nix-config`          | `hms` |
| Check (macOS)    | `nix build .#checks.aarch64-darwin.darwin --no-link` | —     |
| Check (Linux)    | `nix build .#checks.x86_64-linux.home --no-link`     | —     |
| Check everything | `nix flake check` (also evaluates `devShells`)       | —     |
| Update inputs    | `nix flake update`                                  | —     |
| Format repo      | `nix fmt` (nixfmt-tree; `nix fmt -- --ci` to verify) | —     |

There are no tests beyond the `checks` outputs, which build each host's full config.

## Architecture

### Module Layering

```
flake.nix
  └─ modules/home/       (Home Manager: user identity, imports packages.nix + all shared feature modules)
       └─ hosts/darwin/  or  hosts/popos/  (platform-specific overrides)
```

- **`modules/home/default.nix`** is the main hub. User identity, stateVersion, and all shared feature modules are imported from here; machine-basics packages are in `modules/home/packages.nix`.
- **`hosts/`** contains platform-specific config. macOS uses nix-darwin for system-level settings (Dock, Finder, Homebrew, Touch ID sudo). Linux uses Home Manager alone.
- **`modules/` is split by module system**: `modules/home/<name>/` holds Home Manager modules, `modules/darwin/` holds nix-darwin modules. A feature needing both (LinearMouse) has one half in each.
- **Machine basics vs dev work**: `modules/home/packages.nix` is only for tools every host needs regardless of work (core CLI, secrets tooling). Dev tooling goes in a stack module under `modules/home/dev/` (`node`, `php`, `k8s`, `infra`) or `dev/tools.nix`; a new stack gets its own `dev/<stack>/default.nix`, imported from `dev/default.nix`.
- **Platform-only Home Manager modules** (`colima`, `linearmouse`) are imported by `hosts/darwin`, not `modules/home/default.nix`, and carry no `isDarwin` guard. Inline `stdenv.hostPlatform.isDarwin` checks are only for small differences inside shared modules.

### Custom Options

Feature modules declare their own options under `config.custom.<feature>` (e.g. `custom.ssh`, `custom.claudeCode`, `custom.services.colima`). `modules/home/default.nix` declares none.

The username is a single flake-level constant (`userName` in `flake.nix`), threaded into both configs via `specialArgs`/`extraSpecialArgs` — it is not a `custom` option.

### Secrets & SSH Keys

- **SSH keys are generated locally, never stored.** A single activation script (`sshKeys`, driven by the registry in `modules/home/ssh/keys.nix`) generates any missing key in `~/.ssh/`, derives its `.pub` companion, and assembles `allowed_signers` for Git SSH signing. Existing keys are never overwritten, so each key is unique per machine — losing a machine means re-registering its public keys, not recovering a secret.
- **No declarative secret store.** There is currently no `sops-nix` integration, no `secrets.nix`, and no `secrets/*.enc` files. The `sops`/`age`/`pass` CLIs are installed and the Age key is still restored from Bitwarden during bootstrap (`SOPS_AGE_KEY_FILE` points at `~/.config/sops/age/keys.txt`) for ad-hoc manual use, but nothing in this config consumes it declaratively.

### Activation Script Ordering

Scripts use `lib.hm.dag.entryAfter`. SSH key generation, `.pub` derivation, and `allowed_signers` assembly all run in one `sshKeys` script after `writeBoundary`, fed by the SSH key registry in `modules/home/ssh/keys.nix` — within that script, ordering is line order. Other scripts (e.g. `createWorkDir`) also run after `writeBoundary`, the marker meaning all managed files are on disk.

## Key Conventions

- **Nix style**: two-space indentation, opening brace on its own line, use `nixfmt-rfc-style`.
- **New module**: create `modules/home/<name>/default.nix`, import it in `modules/home/default.nix`'s `imports` list (or from `hosts/darwin` if macOS-only).
- **Host-specific packages**: use `lib.mkAfter` in the host file to append lists.
- **Shell aliases**: add to `modules/home/zsh/default.nix`, not `modules/home/default.nix`.
- **New shell helpers** (functions): add inside `programs.zsh.initContent` in `modules/home/zsh/default.nix`.
- **`home.stateVersion`** is set directly in `modules/home/default.nix` (`"25.05"`).
- **Work vs personal git identity** is controlled by a conditional `gitdir:~/work/**` include in `modules/home/git/default.nix`.

## Adding an SSH Key

SSH keys are declared in the registry at `modules/home/ssh/keys.nix`. Append an entry (name, type, whether it signs commits, host routing); the `sshKeys` activation script generates it on the next rebuild, and `modules/home/ssh/config.nix` plus the git module derive host routing and signing from the same registry. Do not hand-write a keygen script.

There is no declarative secret store today. If you need one (e.g. API tokens decrypted at activation), add `sops-nix` as a flake input and a `sops.secrets` module — that wiring is intentionally absent right now.
