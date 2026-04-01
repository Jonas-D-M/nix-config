---
description: Home Manager module patterns for this nix-config repo. Use when creating or modifying modules in the modules/ directory.
user-invocable: false
---

# Home Manager Module Patterns

## Module Creation Checklist

1. Create `modules/<name>/default.nix`
2. Add `./<name>` to the `imports` list in `modules/shared.nix`
3. Run `nixfmt` on both files

## Standard Module Skeleton

```nix
{ config, pkgs, lib, ... }:
{
  # packages
  home.packages = with pkgs; [
    some-package
  ];

  # or use the programs abstraction
  programs.some-program = {
    enable = true;
    # program-specific options
  };
}
```

## The `config.custom` Namespace

Defined in `modules/shared.nix`. Available options:

```nix
config.custom = {
  user                # username (default "jonas")
  extraHomePackages   # per-host package additions
  stateVersion        # Home Manager version (default "25.05")
  homeStateVersion    # override home version
  systemStateVersion  # override system version
};
```

Extend with new options by adding to the `options.custom` block in `shared.nix`.

## Dotfile Management with `home.file`

```nix
# Inline content
home.file.".config/app/config.toml".text = ''
  [section]
  key = "value"
'';

# From a source file in the repo
home.file.".config/app/config.toml".source = ./config.toml;
```

Use `.source` for static files (no Nix interpolation needed). Use `.text` when you need to reference Nix variables or `config` values.

## Packages: `home.packages` vs `programs.<name>.enable`

- **`home.packages`** — just installs the binary, no config management
- **`programs.<name>.enable`** — installs AND manages configuration declaratively

Prefer `programs` when Home Manager has a module for the tool. Fall back to `home.packages` + `home.file` for tools without modules.

## Activation Scripts

For imperative steps that must run at activation time:

```nix
home.activation.myScript = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  run /path/to/command --flag
'';
```

Key ordering constraints in this repo:
- `writeBoundary` (built-in) — all files written
- `generateSshKeys` — decrypts SSH keys from SOPS
- `ensurePubKeys` — generates `.pub` files and `allowed_signers`

Always use `entryAfter` to declare dependencies.

## Shell Configuration

- **Aliases**: add to `modules/zsh/default.nix` in the aliases attrset
- **Functions/init code**: add inside `programs.zsh.initContent` in `modules/zsh/default.nix`
- **Environment variables**: use `home.sessionVariables` or `programs.zsh.sessionVariables`

## Secrets Flow

1. Encrypt with `sops --encrypt --age <recipient>` -> `secrets/<name>.enc`
2. Decrypt in an activation script with `entryAfter [ "writeBoundary" ]`
3. Age key lives at `~/.config/sops/age/keys.txt` (from Bitwarden bootstrap)

## Work vs Personal Git Identity

Controlled by conditional include in `modules/git/default.nix`:

```nix
includes = [
  {
    condition = "gitdir:~/work/**";
    contents = {
      user = {
        email = "work@example.com";
        # ...
      };
    };
  }
];
```

## Platform-Specific Config in Host Files

Host files in `hosts/` use `lib.mkAfter` to append to lists:

```nix
home.packages = lib.mkAfter (with pkgs; [
  host-specific-package
]);
```

This ensures host packages are appended after shared packages.
