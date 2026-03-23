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
  └─ home.nix               (user identity, stateVersion baseline)
       └─ modules/shared.nix  (packages, programs, activation scripts, imports all feature modules)
            └─ hosts/darwin/  or  hosts/popos.nix  (platform-specific overrides)
```

- **`modules/shared.nix`** is the main hub. All feature modules are imported from here, not directly from `flake.nix`.
- **`hosts/`** contains platform-specific config. macOS uses nix-darwin for system-level settings (Dock, Finder, Homebrew, Touch ID sudo). Linux uses Home Manager alone.
- Feature modules live in `modules/<name>/default.nix`.

### Custom Options

`modules/shared.nix` exposes a `config.custom` namespace:

```nix
config.custom = {
  user                # username (default "jonas")
  extraHomePackages   # per-host package additions
  stateVersion        # Home Manager version (default "25.05")
  homeStateVersion    # override home version
  systemStateVersion  # override system version
}
```

### Secrets

- Encrypted with SOPS + Age. Age key lives at `~/.config/sops/age/keys.txt`, retrieved from Bitwarden during bootstrap.
- Encrypted files: `secrets/*.enc` (JSON with `data` key).
- SSH keys are decrypted to `~/.ssh/id_ed25519*`; activation scripts generate `.pub` companions and `allowed_signers` for Git SSH signing.

### Activation Script Ordering

Scripts use `lib.hm.dag.entryAfter`. Secrets-dependent logic (e.g. `ensurePubKeys`) must declare `[ "ensureSshDir" "sops-nix" ]` as dependencies. Breaking this ordering leaves keys or directories missing.

## Key Conventions

- **Nix style**: two-space indentation, opening brace on its own line, use `nixfmt-rfc-style`.
- **New module**: create `modules/<name>/default.nix`, import it in `modules/shared.nix`'s `imports` list.
- **Host-specific packages**: use `lib.mkAfter` in the host file to append lists.
- **Shell aliases**: add to `modules/zsh/default.nix`, not `shared.nix`.
- **New shell helpers** (functions): add inside `programs.zsh.initContent` in `modules/zsh/default.nix`.
- **`home.stateVersion`** appears in both `home.nix` and `shared.nix` — change both together if upgrading.
- **Work vs personal git identity** is controlled by a conditional `gitdir:~/work/**` include in `modules/git/default.nix`.

## Adding a New Secret

1. Encrypt with `sops` using the Age recipient (`age-keygen -y keys.txt`).
2. Store as `secrets/<name>.enc`.
3. Reference in a `sops.secrets` entry inside `secrets.nix`.
4. Any derived artifacts (config files, keys) must be generated in an activation script with `entryAfter [ "sops-nix" ]`.
