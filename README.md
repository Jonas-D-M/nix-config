# nix-config: Home Manager + Nix Flake

## Structure

- `flake.nix`: Entry point for the Nix Flake, defines the home configuration and imports modules.
- `home.nix`: Baseline user identity, state version, and minimal packages.
- `modules/`: Feature modules for shared logic, secrets, shell, git signing, and terminal configuration.
- `hosts/`: Host-specific overrides (e.g., `popos.nix` for Pop!\_OS), desktop settings, and extra packages.
- `media/wallpapers/`: Wallpapers synced to the user background.
- `secrets/`: Encrypted secrets managed by [sops-nix](https://github.com/Mic92/sops-nix).
- `scripts/bootstrap.sh`: Onboarding script for new machines, handles Nix install, Bitwarden unlock, Age key restore, and Home Manager switch.

## Key Features

- **Declarative Environment**: All packages, shell settings, and desktop customizations are managed via Nix modules.
- **Secrets Management**: Uses sops-nix and Age for secure secret decryption. SSH keys and other secrets are restored automatically.
- **Git Signing**: SSH-based git signing with allowed signers generated post-secrets install.
- **Shell Tooling**: Zsh configured with plugins, aliases, and helper functions for secrets and key management.
- **Desktop Customization**: GNOME/Pop!\_OS settings, wallpapers, keyboard shortcuts, and favorites are managed declaratively.
- **Activation Scripts**: Custom activation steps ensure correct ordering for secrets, SSH keys, and derived config files.

## Usage

### Onboarding a New Machine

1. Clone this repo: `git clone https://github.com/Jonas-D-M/nix-config.git`
2. Run the bootstrap script: `cd ~/nix-config && ./scripts/bootstrap.sh`
   - Ensures Nix is installed
   - Unlocks Bitwarden (API key or interactive)
   - Restores Age key for secrets
   - Runs Home Manager switch
3. Log out and back in to apply shell and desktop changes.

### Common Commands

- Switch configuration: `home-manager switch --flake ~/nix-home`
- Dry-run build: `nix build ~/nix-home`
- Update inputs: `nix flake update`

### macOS (nix-darwin) Usage

This flake also defines a Darwin system configuration under `darwinConfigurations.jonas-mac` using [nix-darwin](https://github.com/lnl7/nix-darwin) plus Home Manager:

Evaluate (sanity check):

```sh
nix eval .#darwinConfigurations.jonas-mac.system
```

Build & activate on macOS (after installing nix-darwin):

```sh
darwin-rebuild switch --flake .#jonas-mac
```

Your Home Manager user config is imported with `home.homeDirectory = /Users/jonas`. Secrets still use Age + Bitwarden; ensure the Age key is restored to `~/.config/sops/age/keys.txt` (see `bw-age-restore`).

Host overrides live in `hosts/macos.nix` (Dock/Finder defaults etc.). Extend there for additional macOS-specific behavior (fonts, services, system.defaults).

## Extending the Configuration

- Add new features by creating a module in `modules/` and importing it in `modules/shared.nix`.
- Host-specific tweaks go in `hosts/<hostname>.nix` using `lib.mkAfter`.
- Add secrets by encrypting with sops and referencing in `modules/secrets.nix`.
- Shell helpers and aliases should be added to `modules/zsh.nix`.
