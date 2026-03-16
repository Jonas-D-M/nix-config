# nix-config

Declarative macOS + Linux environment managed with Nix Flakes, Home Manager, and nix-darwin.

## Quick Start

```sh
git clone https://github.com/Jonas-D-M/nix-config.git ~/nix-config
cd ~/nix-config && ./scripts/bootstrap.sh
```

The bootstrap script installs Nix, restores your Age key from Bitwarden, and runs the first build. Log out and back in afterwards to pick up shell changes.

## Daily Commands

| Action | Command | Alias |
|---|---|---|
| Rebuild (Linux) | `home-manager switch --flake ~/nix-config` | `hms` |
| Rebuild (macOS) | `darwin-rebuild switch --flake ~/nix-config` | `drb` |
| Update all inputs | `nix flake update` | — |

## Updating Packages

```sh
cd ~/nix-config
nix flake update          # bump flake.lock to latest nixpkgs + inputs
drb                       # macOS — or hms on Linux
```

Review what changed with `git diff flake.lock` before committing.

## Project Structure

```
flake.nix              # entry point — defines homeConfigurations + darwinConfigurations
home.nix               # baseline user identity and state version
modules/
  shared.nix           # shared packages, programs, and options
  zsh/                 # shell config, aliases, plugins
  git/                 # git + signing
  ssh/                 # SSH key generation and config
  wezterm/             # terminal emulator
  openfortivpn/        # VPN module
  k9s/                 # Kubernetes TUI skin
  darwin/              # macOS-only modules (aerospace, linearmouse)
hosts/
  darwin/              # nix-darwin system config (Dock, Finder, Homebrew, etc.)
  popos.nix            # Pop!_OS / Linux host overrides
scripts/
  bootstrap.sh         # first-run onboarding script
media/
  wallpapers/          # desktop wallpapers
```

## Adding Packages / Modules

- **Shared packages** — add to the `baseHomePackages` list in `modules/shared.nix`.
- **New module** — create a directory under `modules/`, then import it in `modules/shared.nix`.
- **Host-specific tweaks** — edit `hosts/darwin/default.nix` (macOS) or `hosts/popos.nix` (Linux).
- **Shell aliases** — add to `modules/zsh/default.nix`.
