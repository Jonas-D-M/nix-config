# Copilot Agent Instructions for nix-config

Purpose: This repo is a Home Manager + Nix Flake configuration for user "jonas". Agents should help evolve declarative system/user environment, secrets integration, and shell tooling.

## Core Architecture

- Entry point: `flake.nix` defines `homeConfigurations."jonas-home"` composed of `home.nix`, `modules/shared.nix`, and host-specific overrides in `hosts/popos.nix`.
- Pattern: Put broadly shared logic in `modules/shared.nix`; host-/machine-specific tweaks live under `hosts/`. Import additional feature modules from `shared.nix` via its `imports` list.
- Module layering: `home.nix` sets identity + baseline `home.stateVersion` and a few simple packages; `shared.nix` expands packages, activation steps, and imports; `hosts/popos.nix` appends packages with `lib.mkAfter` and applies desktop/dconf settings.
- Activation DAG: Custom activation scripts are defined via `home.activation.<name> = lib.hm.dag.entryAfter [ ... ] ''<bash>'';`. Respect declared ordering (e.g. `ensurePubKeys` depends on secrets being installed: `[ "ensureSshDir" "sops-nix" ]`).

## Secrets & Signing Flow

- Secrets managed with `sops-nix` (module imported as `sops-nix.homeManagerModules.sops`). Age key path: `~/.config/sops/age/keys.txt` (see `secrets.nix`).
- Encrypted secret files live in `secrets/*.enc` (JSON format with key `data`). Decryption happens automatically once the Age key is restored.
- SSH keys: decrypted to `~/.ssh/id_ed25519*`; activation script generates `.pub` companions and `allowed_signers` for Git SSH signing.
- Git signing uses SSH (`programs.git.settings.gpg.format = "ssh"`) and `allowed_signers` generated post-secret install.

## Bootstrap Workflow

- Primary onboarding script: `scripts/bootstrap.sh`. Responsibilities: ensure Nix installed, Bitwarden login/unlock, restore Age key, test decrypt, then run Home Manager switch with the flake ref (default ref defined in `flake.nix`).
- Bitwarden: script supports API key login via `BW_CLIENTID` / `BW_CLIENTSECRET` env vars; interactive otherwise.
- Age key retrieval: script expects secure note name argument (default variable shows `age-key` while zsh functions use "Nix Age Key" — confirm desired canonical name before adding new secrets).

## Shell & Tooling Conventions

- Zsh configured via `modules/zsh.nix`: bootstraps NVM, pnpm path injection, direnv, zinit plugin set (syntax highlighting, completions, autosuggestions, fzf-tab), custom history and keybindings.
- Helper functions defined inside `programs.zsh.initContent`: `bw-unlock`, `bw-age-restore`. When adding new shell helpers place them here to ensure declarative management.
- Aliases centralization: lightweight global aliases in `shared.nix` (`home.shellAliases`) plus extra ones inside the zsh init block.
- Formatting: use `nixfmt-rfc-style` (installed) for Nix code. Keep module style consistent (attribute set brace on its own line, two-space indentation).

## Adding/Modifying Modules

- New feature module: create `modules/<name>.nix` exporting a NixOS/Home Manager module attrset; import it by appending path to `imports` in `shared.nix` (not directly in `flake.nix`).
- Host-specific additions: use `lib.mkAfter` in host file to append or override lists (e.g. extra packages in `hosts/popos.nix`). Avoid duplicating logic from shared modules.
- Activation scripts: prefer small idempotent bash blocks with `set -euo pipefail`; place secrets-dependent logic after relevant steps via `entryAfter`.

## Secrets Workflow Extensions

- To add a new secret: encrypt with `sops` + Age recipient (from `age-keygen -y keys.txt`), store as `secrets/<name>.enc` referencing it in a new `sops.secrets."ssh/<file>"` entry or other path inside `secrets.nix`.
- Ensure any derived artifacts (e.g. generated config files) happen in an activation script that runs after `sops-nix`.

## Git & Work Context

- Work vs personal git identity switching handled by conditional include (`condition = "gitdir:${config.home.homeDirectory}/work/**"`) creating `.gitconfig-work-ssh` override. To extend: add additional include blocks keyed by `gitdir:` patterns.

## Desktop Customization

- `hosts/popos.nix` manages GNOME / PopOS dconf settings and wallpapers. Wallpapers are synced via `home.file` recursion from `media/wallpapers/w11` -> `~/.local/share/backgrounds/w11`.
- Keyboard shortcuts & favorites defined declaratively; modify there instead of manual dconf editing.

## Common Tasks

- Switch configuration after edits: $ home-manager switch --flake <home-flake>
- Dry-run build (evaluation only): $ nix build <home-flake>
- Default value for <home-flake> is the single home configuration declared in `flake.nix`.
- Update inputs: `nix flake update` then commit lock file (if present; currently implicit due to missing `flake.lock` — add lock for reproducibility when updating).

## Cautions & Gotchas

- Keep `home.stateVersion` consistent; do not bump casually (present in both `home.nix` and `shared.nix`, intentional duplication—change both together if upgrading).
- Maintain ordering of activation scripts; breaking dependencies may leave `allowed_signers` or directories missing.
- Align Bitwarden note names across bootstrap script and zsh helper to avoid silent key mismatch.

## Extending for CI / Agents

- When adding automation (CI, pre-commit), ensure non-interactive secrets retrieval (export Bitwarden API env vars or inject Age key directly).
- Keep instructions here updated whenever new modules or workflows (e.g. container or Kubernetes tooling) are added to `home.packages`.

Feedback requested: Clarify any ambiguous secret naming, desired lockfile strategy, or additional workflows to document.
