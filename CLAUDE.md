# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Declarative macOS + Linux environment managed with Nix Flakes, Home Manager, and nix-darwin. Supports both Linux (Pop!\_OS, x86_64) and macOS (Apple Silicon) from a single flake.

## Build & Apply Commands

| Action           | Command                                             | Alias |
| ---------------- | --------------------------------------------------- | ----- |
| Apply (macOS)    | `sudo darwin-rebuild switch --flake ~/nix-config`   | `drb` |
| Apply (Linux)    | `home-manager switch --flake ~/nix-config`          | `hms` |
| Dry-run (macOS)  | `nix build .#darwinConfigurations.jonas-mac.system` | —     |
| Dry-run (Linux)  | `nix build .#homeConfigurations.jonas`              | —     |
| Update inputs    | `nix flake update`                                  | —     |
| Format Nix files | `nixfmt` (nixfmt-rfc-style)                         | —     |

There are no tests beyond a successful `nix build` dry-run.

## Architecture

### Module Layering

```
flake.nix
  └─ modules/shared.nix  (user identity, packages, programs, activation scripts, imports all feature modules)
       └─ hosts/darwin/  or  hosts/popos.nix  (platform-specific overrides)
```

- **`modules/shared.nix`** is the main hub. User identity, stateVersion, and all feature modules are imported from here.
- **`hosts/`** contains platform-specific config. macOS uses nix-darwin for system-level settings (Dock, Finder, Homebrew, Touch ID sudo). Linux uses Home Manager alone.
- Feature modules live in `modules/<name>/default.nix`.

### Custom Options

`modules/shared.nix` exposes a `config.custom` namespace:

```nix
config.custom = {
  extraHomePackages   # per-host package additions
  stateVersion        # base Home Manager state version (default "25.05")
  homeStateVersion    # override home version (defaults to stateVersion)
}
```

The username is a single flake-level constant (`userName` in `flake.nix`), threaded into both configs via `specialArgs`/`extraSpecialArgs` — it is not a `custom` option.

### Secrets & SSH Keys

- **SSH keys are generated locally, never stored.** A single activation script (`sshKeys`, driven by the registry in `modules/ssh/keys.nix`) generates any missing key in `~/.ssh/`, derives its `.pub` companion, and assembles `allowed_signers` for Git SSH signing. Existing keys are never overwritten, so each key is unique per machine — losing a machine means re-registering its public keys, not recovering a secret.
- **No declarative secret store.** There is currently no `sops-nix` integration, no `secrets.nix`, and no `secrets/*.enc` files. The `sops`/`age`/`pass` CLIs are installed and the Age key is still restored from Bitwarden during bootstrap (`SOPS_AGE_KEY_FILE` points at `~/.config/sops/age/keys.txt`) for ad-hoc manual use, but nothing in this config consumes it declaratively.

### Activation Script Ordering

Scripts use `lib.hm.dag.entryAfter`. SSH key generation, `.pub` derivation, and `allowed_signers` assembly all run in one `sshKeys` script after `writeBoundary`, fed by the SSH key registry in `modules/ssh/keys.nix` — within that script, ordering is line order. Other scripts (e.g. `createWorkDir`) also run after `writeBoundary`, the marker meaning all managed files are on disk.

## Key Conventions

- **Nix style**: two-space indentation, opening brace on its own line, use `nixfmt-rfc-style`.
- **New module**: create `modules/<name>/default.nix`, import it in `modules/shared.nix`'s `imports` list.
- **Host-specific packages**: use `lib.mkAfter` in the host file to append lists.
- **Shell aliases**: add to `modules/zsh/default.nix`, not `shared.nix`.
- **New shell helpers** (functions): add inside `programs.zsh.initContent` in `modules/zsh/default.nix`.
- **`home.stateVersion`** is set in `shared.nix` via `config.custom.homeStateVersion` (default `"25.05"`).
- **Work vs personal git identity** is controlled by a conditional `gitdir:~/work/**` include in `modules/git/default.nix`.

## Adding an SSH Key

SSH keys are declared in the registry at `modules/ssh/keys.nix`. Append an entry (name, type, whether it signs commits, host routing); the `sshKeys` activation script generates it on the next rebuild, and `modules/ssh/config.nix` plus the git module derive host routing and signing from the same registry. Do not hand-write a keygen script.

There is no declarative secret store today. If you need one (e.g. API tokens decrypted at activation), add `sops-nix` as a flake input and a `sops.secrets` module — that wiring is intentionally absent right now.
