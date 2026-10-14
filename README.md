# nix-config

Declarative macOS + Linux environment managed with Nix Flakes, Home Manager, and nix-darwin. One flake configures two machines: a MacBook Pro (Apple Silicon) and a Pop!\_OS desktop (x86_64). One command fully configures either machine: packages, dotfiles, shell, SSH keys, Git identity, Docker.

## Quick Start

```sh
git clone https://github.com/Jonas-D-M/nix-config.git ~/nix-config
cd ~/nix-config && ./scripts/bootstrap.sh
```

The bootstrap script installs Nix, restores your Age key from Bitwarden, and runs the first build. Log out and back in afterwards to pick up shell changes.

## Daily Commands

| Action            | Command                                              | Alias |
| ----------------- | ---------------------------------------------------- | ----- |
| Rebuild (macOS)   | `sudo darwin-rebuild switch --flake ~/nix-config`    | `drb` |
| Rebuild (Linux)   | `home-manager switch --flake ~/nix-config`           | `hms` |
| Check (macOS)     | `nix build .#checks.aarch64-darwin.darwin --no-link` | —     |
| Check (Linux)     | `nix build .#checks.x86_64-linux.home --no-link`     | —     |
| Check everything  | `nix flake check`                                    | —     |
| Format            | `nix fmt`                                            | —     |
| Update all inputs | `nix flake update`                                   | —     |
| Garbage collect   | `nix-cleanup` (also runs weekly, keeping 30 days)    | —     |

After `nix flake update`, run the check before rebuilding: nixos-unstable occasionally breaks packages. Temporary fixes for that go in `overlays/`.

## Layout

```
flake.nix              inputs, nixpkgs settings, the two host configs, checks
overlays/              nixpkgs overlays; temporary upstream workarounds say when to remove them
hosts/
  darwin/              macOS: nix-darwin system settings, Homebrew casks, HM wiring
  popos/               Pop!_OS: standalone Home Manager, GNOME/dconf, wallpaper
modules/
  home/                Home Manager modules (user level), entry point default.nix
    packages.nix       machine basics every host needs (core CLI, secrets tooling)
    dev/               dev tooling, one module per stack: node, php, k8s, infra, tools.nix
    <feature>/         shell, git, ssh, editors, claude-code, … (one dir each)
  darwin/              nix-darwin modules (system level)
```

Each module starts with a header comment saying what it manages. Read that before the code.

## Adding Things

- **Machine basics** (needed regardless of dev work): `modules/home/packages.nix`
- **Dev tooling**: the matching stack in `modules/home/dev/`, or `dev/tools.nix` if it fits none
- **New feature module**: `modules/home/<name>/default.nix`, imported from `modules/home/default.nix`
- **macOS-only module**: same place, but imported from `hosts/darwin` instead
- **Host-specific packages**: `home.packages = lib.mkAfter [ … ];` in the host file
- **GUI apps on macOS**: Homebrew casks in `hosts/darwin/homebrew.nix`
- **Shell aliases and functions**: `modules/home/zsh/default.nix`

## How It Fits Together

**Two evaluation strategies.** On macOS, nix-darwin owns the evaluation and Home Manager runs inside it as a module (`useGlobalPkgs`), so one nixpkgs instance serves both. On Linux there is no system layer: the flake instantiates `pkgs` itself and hands it to standalone Home Manager. Both get the same nixpkgs settings (`allowUnfree`, `overlays/default.nix`) from `nixpkgsArgs` in `flake.nix`. The only special argument either config receives is `userName`.

**Module systems are kept apart.** `modules/home/` is user-level Home Manager config; `modules/darwin/` is system-level nix-darwin config. A feature that needs both, like LinearMouse, has one half in each.

**Platform gating happens at import time.** Modules that only make sense on one OS (`colima`, `linearmouse`) are imported by that host and carry no `isDarwin` guard. Inline `stdenv.hostPlatform.isDarwin` checks are only for small differences inside shared modules (e.g. VS Code and WezTerm come from Homebrew on macOS, so their Nix packages are stubbed out there).

**Options live with their feature.** Modules declare their own `config.custom.<feature>` options (`custom.ssh`, `custom.claudeCode`, `custom.services.colima`, `custom.darwin.homebrew`); hosts set them. There is no central options file.

**macOS host.** Beyond Home Manager, nix-darwin manages Touch ID for sudo, machine names, Dock/Finder/keyboard/trackpad defaults, power settings, and Homebrew. `nix-homebrew` installs and owns `/opt/homebrew`, so a fresh Mac needs no manual `brew` setup; casks not listed are removed on rebuild (`cleanup = "zap"`). Docker runs through Colima, started at login by launchd.

**Linux host.** Purely user-space: dconf drives GNOME/Pop Shell behaviour, wallpapers are synced from `media/wallpapers/`, and Docker is a plain package.

## Secrets and SSH Keys

There is **no declarative secret store**: no `sops-nix`, no encrypted files in the repo.

- **SSH keys are generated on each machine**, never stored. The registry in `modules/home/ssh/keys.nix` lists every key; an activation script creates any missing one, derives its `.pub`, and writes `allowed_signers` for Git signing. Keys are never overwritten, so each machine has its own. Losing a machine means re-registering its public keys with GitHub/Azure, not restoring a secret.
- **Work vs personal identity** is chosen by directory: anything under `~/work` uses the work SSH key and Git identity.
- **The Age key** is restored from Bitwarden at bootstrap and `SOPS_AGE_KEY_FILE` points to it. `sops`, `age`, and `pass` are installed for manual use; nothing in the config depends on them.

If you need declarative secrets later, add `sops-nix` as a flake input and a `sops.secrets` module.
