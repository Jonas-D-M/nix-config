# Copilot Instructions for nix-config

Declarative macOS + Linux environment managed with Nix Flakes, Home Manager, and
nix-darwin, for user `jonas`. One flake configures two machines: an Apple Silicon
MacBook and a Pop!\_OS (x86_64) desktop.

## Architecture

```
flake.nix
  └─ modules/shared.nix   (the hub: identity, base packages, config.custom, imports every feature module)
       ├─ hosts/darwin/   (macOS, nix-darwin: Dock, Finder, Homebrew, Touch ID)
       └─ hosts/popos.nix (Linux, Home Manager: GNOME/dconf, wallpapers)
```

- `flake.nix` exposes two outputs: `homeConfigurations."jonas"` (Linux, standalone
  Home Manager — `pkgs` is instantiated in the flake) and
  `darwinConfigurations."jonas-mac"` (macOS, nix-darwin with Home Manager as a module
  and `useGlobalPkgs = true`).
- `modules/shared.nix` evaluates in Home Manager context on both platforms, so it may
  only set **user-level** options. It declares the `config.custom` option namespace.
- Feature modules live at `modules/<name>/default.nix` and are imported via the
  `imports` list in `shared.nix`.
- There is **no** `home.nix` and **no** `secrets.nix`.

## Conventions

- **New feature module:** create `modules/<name>/default.nix`, add `./<name>` to the
  `imports` list in `modules/shared.nix`, run `nixfmt` (nixfmt-rfc-style: two-space
  indent, opening brace on its own line).
- **Shared packages:** add to `baseHomePackages` in `modules/shared.nix`.
- **Host-specific packages:** append with `lib.mkAfter` in the host file.
- **Shell aliases:** `shellAliases` attrset in `modules/zsh/default.nix` (not
  `shared.nix`). **Shell functions / init code:** inside `programs.zsh.initContent`
  in the same file.
- **Per-platform deltas:** gate single-platform modules with `lib.mkIf
  pkgs.stdenv.isDarwin`; use `lib.optionals pkgs.stdenv.isDarwin [...]` for
  per-attribute differences.
- **Custom options namespace** (declared in `shared.nix`): `custom.user`,
  `custom.extraHomePackages`, `custom.stateVersion`, `custom.homeStateVersion`, plus
  module sub-namespaces like `custom.services.colima` and `custom.darwin.homebrew`.

## SSH Keys & Secrets

- **No declarative secret store** — no `sops-nix`, no `secrets/*.enc`. The `sops`/`age`
  CLIs are installed for manual use only; the Age key is restored from Bitwarden
  during bootstrap.
- **SSH keys are generated locally.** The registry in `modules/ssh/keys.nix` is the
  single source of truth; the `sshKeys` activation script generates any missing key,
  derives `.pub` files, and writes `allowed_signers`. Existing keys are never
  overwritten. To add a key, append to the registry — do not hand-write a keygen step.
- **Git signing** is SSH-based (`gpg.format = "ssh"`); `allowed_signers` is produced by
  the ssh module. Work vs personal identity switches via a `gitdir:~/work/**`
  conditional include in `modules/git/default.nix`.

## Activation Scripts

Use `home.activation.<name> = lib.hm.dag.entryAfter [ "writeBoundary" ] ''<bash>'';`.
`writeBoundary` means all managed files are on disk. A script that needs the generated
SSH keys should use `entryAfter [ "sshKeys" ]`. Prefer small, idempotent bash with
`set -euo pipefail`; guard with `[ ! -f ]`/`[ ! -d ]` so reruns never clobber.

## Build, Apply, Update

- **Dry-run:** macOS `nix build .#darwinConfigurations.jonas-mac.system`;
  Linux `nix build .#homeConfigurations.jonas`.
- **Apply:** macOS `drb` (`sudo darwin-rebuild switch --flake ~/nix-config`);
  Linux `hms` (`home-manager switch --flake ~/nix-config`).
- **Update inputs:** `nix flake update`, then dry-run before committing `flake.lock`
  (which **is** tracked).
- There are no tests beyond a successful dry-run build.
