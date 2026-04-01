# nix-config

Declarative macOS + Linux environment managed with Nix Flakes, Home Manager, and nix-darwin.

## Quick Start

```sh
git clone https://github.com/Jonas-D-M/nix-config.git ~/nix-config
cd ~/nix-config && ./scripts/bootstrap.sh
```

The bootstrap script installs Nix, restores your Age key from Bitwarden, and runs the first build. Log out and back in afterwards to pick up shell changes.

## Daily Commands

| Action            | Command                                             | Alias |
| ----------------- | --------------------------------------------------- | ----- |
| Rebuild (macOS)   | `sudo darwin-rebuild switch --flake ~/nix-config`   | `drb` |
| Rebuild (Linux)   | `home-manager switch --flake ~/nix-config`          | `hms` |
| Dry-run (macOS)   | `nix build .#darwinConfigurations.jonas-mac.system` | —     |
| Dry-run (Linux)   | `nix build .#homeConfigurations.jonas`              | —     |
| Update all inputs | `nix flake update`                                  | —     |
| Garbage collect   | `nix-cleanup`                                       | —     |

## Adding Things

- **Shared packages** — add to `baseHomePackages` in `modules/shared.nix`
- **New module** — create `modules/<name>/default.nix`, import it in `modules/shared.nix`
- **Host-specific packages** — use `lib.mkAfter` in the host file
- **Shell aliases** — add to `modules/zsh/default.nix`
- **Shell functions** — add inside `programs.zsh.initContent` in `modules/zsh/default.nix`

---

## Understanding This Config

The rest of this document explains how the repository is structured, why it is designed the way it is, and what each part is responsible for.

### 1. The Big Picture

This repository is a single source of truth for two machines: a MacBook Pro (Apple Silicon, macOS) and a desktop running Pop!\_OS (x86_64 Linux). Both are configured declaratively from one Nix flake. The goal is that after running a single command, either machine is fully configured: packages installed, dotfiles placed, shell set up, SSH keys generated, Git identity correct, Docker running.

No manual steps. No configuration drift between machines.

---

### 2. How the Pieces Fit Together

The configuration is layered. Each layer adds specificity:

```
flake.nix
  └─ modules/shared.nix   (identity, packages, programs, all feature modules)
       └─ hosts/darwin/   (macOS-only: system settings, Homebrew, launchd)
       └─ hosts/popos.nix (Linux-only: GNOME/dconf settings)
```

#### `flake.nix` — the entry point

The flake declares two outputs:

- `homeConfigurations.jonas` — for Pop!\_OS. Uses standalone Home Manager. `pkgs` is instantiated in the flake itself and passed in, because `useGlobalPkgs` is not available in standalone mode.
- `darwinConfigurations.jonas-mac` — for macOS. Uses nix-darwin, with Home Manager loaded as a nix-darwin module (`home-manager.darwinModules.home-manager`). nix-darwin controls the outer evaluation and Home Manager runs inside it.

The two evaluation strategies differ. On macOS, `home-manager.useGlobalPkgs = true` means nixpkgs is instantiated once at the nix-darwin level and shared with Home Manager — hence why `pkgs` is _not_ pre-instantiated in the flake for darwin. On Linux there is no outer nix-darwin, so the flake instantiates `pkgs` directly.

Additional flake inputs:

- **`nix-shells`** — reusable dev shells from a separate repo, re-exported as `devShells`
- **`nix-vscode-extensions`** — overlay that provides `vscode-marketplace` and `vscode-marketplace-release` attrs, used by the VS Code module to install extensions from the marketplace

#### `modules/shared.nix` — the hub

This is where almost everything real happens. It:

- Sets user identity (`home.username`, `home.homeDirectory` — resolved per-platform)
- Imports all feature modules
- Declares the `config.custom` option namespace (see section 6)
- Defines the base package list (`baseHomePackages`)
- Configures cross-platform programs: `direnv`, `kubeswitch`, `gh`, `openfortivpn`
- Enables `xdg` and silences Home Manager news
- Sets `home.stateVersion` and session variables (`KUBECONFIG`, `SOPS_AGE_KEY_FILE`)
- Runs the `createWorkDir` activation script to ensure `~/work` exists

`shared.nix` is imported under `home-manager.users.jonas.imports` on macOS and directly in the `modules` list on Linux. Either way it evaluates in Home Manager context and may only contain user-level options.

#### `hosts/` — platform overrides

Host files sit on top of `shared.nix` and add what is platform-specific. They cannot replace what shared defines, but they can extend it (e.g. appending packages with `lib.mkAfter`).

---

### 3. The Two Platforms, Side by Side

#### macOS (`hosts/darwin/default.nix`)

On macOS, nix-darwin owns the outer evaluation. This gives access to system-level settings that Home Manager cannot touch:

- **Touch ID for sudo** (`security.pam.services.sudo_local.touchIdAuth` + `reattach`)
- **Networking** — sets `computerName`, `hostName`, and `localHostName`
- **Homebrew** — GUI apps and casks that are not in nixpkgs or better installed as native `.app` bundles (WezTerm, VS Code, Chrome, Slack, Spotify, DBeaver, Postman, Figma, Obsidian, Claude, ChatGPT, Bitwarden, etc.). `onActivation.cleanup = "zap"` means any cask not listed in the config will be removed on the next apply. Microsoft Office casks are controlled by the `custom.darwin.homebrew.microsoft-office.enable` option (default `true`).
- **Dock, Finder, keyboard repeat, trackpad, Control Center** via `system.defaults`
- **Startup chime** disabled
- **Power settings** — the machine never sleeps when on power; auto-restart after freeze is enabled
- **Siri** — status menu icon hidden
- **Guest login** disabled
- **nix-darwin version** pinned at `system.stateVersion = 6`

The host also imports `modules/darwin/linearmouse` (system-level: Homebrew install + trackpad natural scroll).

#### Linux (`hosts/popos.nix`)

On Pop!\_OS there is no system-level management — only Home Manager. Platform-specific config is purely user-space:

- **dconf** settings drive all GNOME/Pop Shell behaviour: color scheme (light), wallpaper, lock screen, touchpad, keyboard shortcuts, app favorites, workspace navigation
- **Wallpaper** files are synced from `media/wallpapers/w11/` into `~/.local/share/backgrounds/w11/` via `home.file`
- **Docker** is added as a package directly (no VM needed on Linux)
- Pop Shell tiling is intentionally disabled (`tile-by-default = false`)

---

### 4. Feature Modules

Each module lives at `modules/<name>/default.nix` and is imported by `shared.nix`. They are self-contained: a module owns its program config, packages, activation scripts, and generated files.

#### `zsh`

The shell. Configures:

- Syntax highlighting, autosuggestions, fzf-tab completion
- `starship` prompt (time on right, direnv status visible)
- `zoxide` (`cd` aliased to `z`), `eza` (`ls` aliased to `eza`), `fzf`
- `fnm` for Node version management, `pnpm`
- History search on `^p`/`^n`, word navigation keybindings
- Aliases: `drb`, `hms`, `nix-cleanup`, `sail`, `neofetch`
- Session path includes `~/.krew/bin`, `~/.local/share/pnpm`, `~/bin`, `~/.local/bin`

#### `git`

Git with SSH-based commit signing. Key behaviours:

- **Personal identity** is the global default: `Jonas-D-M@users.noreply.github.com`, signing key `~/.ssh/id_ed25519`
- **Work identity** activates automatically for any repo under `~/work/**` via a `gitdir:` conditional include. Work commits use `Jonas-PRF@users.noreply.github.com` and `~/.ssh/id_ed25519_work`, and `core.sshCommand` forces that specific key so agent negotiation cannot leak the wrong identity.
- `pull.ff = only` — no surprise merge commits on pull
- All commits and tags are signed (`commit.gpgSign = true`, `tag.gpgSign = true`)
- The `allowed_signers` file (generated by the ssh module) tells Git which public keys are valid for signature verification

#### `ssh`

Split into two files:

**`config.nix`** — the SSH client config:

- GitHub connections use `id_ed25519` by default
- When the current working directory is inside `~/work/`, a `Match exec` block switches to `id_ed25519_work` (handles macOS path normalization via `sed`)
- Azure DevOps (`ssh.dev.azure.com`) always uses `id_rsa_azure_devops`
- Agent forwarding is off globally

**`keygen.nix`** — activation scripts that generate keys if they do not already exist (never overwrite):

- `id_ed25519` — personal (ed25519)
- `id_ed25519_work` — work (ed25519)
- `id_rsa_azure_devops` — Azure DevOps requires RSA, so this is 4096-bit RSA

After generation, `ensurePubKeys` derives the `.pub` files and writes `~/.ssh/allowed_signers` for Git signature verification.

#### `wezterm`

Terminal emulator configuration.

#### `ralph`

An AI coding agent loop tool. Builds two shell scripts from Nix:

- **`ralph-once`** — runs one Claude iteration against `PRD.md` and `progress.txt` in the current directory
- **`ralph <N>`** — runs up to N iterations autonomously, stopping early if Claude outputs `<promise>COMPLETE</promise>`

Both run Claude inside `srt` (sandbox-runtime), which provides OS-level isolation. Two sandbox configs are written to `~`:

- `~/.srt-settings.json` — standard projects: no local port binding, SSH secrets blocked, `.env` files write-protected
- `~/.srt-settings-sail.json` — Laravel Sail projects: PTY enabled, weaker nested sandbox (needed for Docker-in-Docker), local binding allowed, `~/.colima` and `~/.docker` readable

Auto-detection: if `vendor/bin/sail` exists in the current directory, the Sail settings are used and the prompt instructs Claude to use Sail commands instead of bare `php`/`composer`. The SSH agent socket is injected into the sandbox at runtime.

#### `claude-code`

Writes `~/.claude/settings.json`. The only setting is a `Stop` hook that plays a sound when Claude finishes — `afplay` on macOS, `paplay` on Linux.

#### `k9s`

Kubernetes cluster TUI. Enabled with a transparent skin (`transparent.yaml`) so it blends with the terminal background.

#### `node`

Node.js tooling:

- `fnm` for Node version management, `pnpm` as the package manager
- `PNPM_HOME` set and added to `sessionPath`
- A default `~/.nvmrc` pinned to Node 20

#### `vscode`

Full VS Code configuration managed declaratively. On macOS the package itself is installed via Homebrew (the Nix package is replaced with an empty directory stub), while on Linux the Nix package is used directly.

Key settings:

- **Theme**: Tokyo Night Storm with Material Icon Theme
- **Font**: JetBrainsMono Nerd Font with ligatures
- **Editor**: format on save/paste, sidebar on right, minimap disabled, Vim keybindings
- **Formatters**: Prettier for JS/TS/HTML/SCSS/JSON/Vue/Markdown, Intelephense for PHP
- **Extensions**: ~60 extensions installed from `nix-vscode-extensions` marketplace — covers languages (TypeScript, PHP, Python, Nix, Lua, Bash, YAML, TOML), frameworks (React, Laravel, Tailwind, Helm), tools (Docker, Kubernetes, Git, GitHub Actions, Playwright), and AI (Copilot, Claude Code)
- **Terminal**: uses Nix-managed `zsh` on macOS, login `zsh` on Linux
- **Copilot**: enabled globally (disabled for YAML and Markdown)
- **Custom keybindings**: `ctrl+tab`/`ctrl+shift+tab` for editor cycling, `ctrl+space` for suggestions

An activation script makes `settings.json` mutable after Home Manager writes it, so VS Code can update settings at runtime without conflicts.

#### `openfortivpn`

Enables the `openfortivpn` Home Manager program and creates a shell alias.

#### `colima`

Docker runtime for macOS via Lima VM (no Docker Desktop). Lives at `modules/colima` and is guarded by `mkIf (cfg.enable && pkgs.stdenv.isDarwin)`. Defined as a custom option (`custom.services.colima.enable`) and enabled from the flake's darwin configuration.

When enabled:

- Adds `colima`, `docker`, `docker-compose` to the user's packages
- Sets `DOCKER_HOST` to the Colima socket path
- Registers a launchd agent that starts Colima at login, with `colima stop --force` pre-run to clean up stale VM state from unclean shutdowns

#### `linearmouse`

Mouse configuration for macOS via LinearMouse. Split into two modules:

- **`modules/linearmouse`** (Home Manager): registers a launchd agent that launches LinearMouse at login (with a 5-second delay for WindowServer readiness) and seeds a default config to `~/.config/linearmouse/linearmouse.json` if none exists. Source config lives at `modules/darwin/linearmouse/config.json`.
- **`modules/darwin/linearmouse`** (nix-darwin): installs LinearMouse via Homebrew and sets trackpad natural scrolling. Controlled by `custom.services.linearmouse.enable`.

---

### 5. Secrets (SOPS + Age)

Secrets are encrypted with SOPS using an Age key. The Age private key lives at `~/.config/sops/age/keys.txt` (retrieved from Bitwarden during bootstrap — this key is never in the repo).

- Encrypted secret files are stored as `secrets/*.enc` (JSON with a `data` key)
- A `secrets.nix` file declares `sops.secrets` entries pointing to those files
- At activation time, SOPS decrypts secrets to their target paths
- Activation scripts that depend on decrypted secrets must declare `[ "sops-nix" ]` as a dependency (see section 7)

The `SOPS_AGE_KEY_FILE` session variable points to the key location so SOPS can find it without extra flags.

To add a new secret:

1. Encrypt with `sops` using the Age recipient (`age-keygen -y keys.txt`)
2. Store as `secrets/<name>.enc`
3. Add a `sops.secrets` entry in `secrets.nix`
4. Generate derived artifacts in an activation script with `entryAfter [ "sops-nix" ]`

---

### 6. The `config.custom` API

`modules/shared.nix` exposes a small option namespace so host files can customize shared behaviour without editing the shared module:

| Option                      | Type        | Default                 | Purpose                                                |
| --------------------------- | ----------- | ----------------------- | ------------------------------------------------------ |
| `custom.user`               | `str`       | `"jonas"`               | Username used by modules that need it                  |
| `custom.extraHomePackages`  | `[package]` | `[]`                    | Packages appended to the base list for a specific host |
| `custom.stateVersion`       | `str`       | `"25.05"`               | Base version for both home and system                  |
| `custom.homeStateVersion`   | `str`       | inherits `stateVersion` | Override home version independently                    |
| `custom.systemStateVersion` | `str`       | inherits `stateVersion` | Override system version independently                  |

Host files use `lib.mkAfter` when appending to lists to ensure merge ordering is respected. Individual modules add their own sub-namespaces (e.g. `custom.services.colima`, `custom.darwin.homebrew`).

---

### 7. Activation Script Ordering

Home Manager activation scripts run in a DAG (directed acyclic graph). `lib.hm.dag.entryAfter ["dep"]` declares that a script must run after `"dep"` completes.

The SSH key chain:

```
writeBoundary
  └─ generateSshKeys    (creates ~/.ssh, generates missing keys)
       └─ ensurePubKeys (derives .pub files, writes allowed_signers)
```

`writeBoundary` is a built-in Home Manager marker meaning "all managed files have been written". Keygen runs after this so `~/.ssh` exists. `ensurePubKeys` runs after keygen because it needs the private keys to derive public keys.

If you add an activation script that depends on a decrypted secret, use `entryAfter [ "sops-nix" ]`. If it also needs SSH keys, use `entryAfter [ "sops-nix" "ensurePubKeys" ]`. A missing dependency here means the script runs before its inputs are ready — the failure mode is a silent missing file, not a loud error.

---

### 8. The Apply Loop

1. **Edit** a `.nix` file
2. **Dry-run** to check for errors before applying:
   - macOS: `nix build .#darwinConfigurations.jonas-mac.system`
   - Linux: `nix build .#homeConfigurations.jonas`
3. **Apply**:
   - macOS: `drb` (`sudo darwin-rebuild switch --flake ~/nix-config`)
   - Linux: `hms` (`home-manager switch --flake ~/nix-config`)

To update all flake inputs to their latest commits: `nix flake update`. After updating, dry-run first — nixpkgs-unstable occasionally breaks packages. Review what changed with `git diff flake.lock` before committing.

Format Nix files with `nixfmt` (nixfmt-rfc-style: two-space indentation, opening brace on its own line).
