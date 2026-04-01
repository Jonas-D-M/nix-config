---
description: Nix language patterns and idioms. Use when writing or modifying Nix expressions, flakes, or modules.
user-invocable: false
---

# Nix Flake Patterns

## Flake Structure

A flake has `inputs` (dependencies) and `outputs` (what it produces):

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";  # pin to same nixpkgs
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    # darwinConfigurations, homeConfigurations, etc.
  };
}
```

The `follows` pattern avoids duplicate nixpkgs evaluations.

## Function Header Pattern

Every module file uses this destructured argument set:

```nix
{ config, pkgs, lib, ... }:
```

The `...` is required — it allows the module system to pass extra arguments the module doesn't use.

## Option Declaration

```nix
options.custom.myOption = lib.mkOption {
  type = lib.types.str;        # or: bool, int, listOf str, attrsOf str, nullOr str
  default = "value";
  description = "What this option controls";
};
```

Use `config.custom.myOption` to read the value in other modules.

## Option Priority

From lowest to highest priority:

| Function | Priority | Use case |
|---|---|---|
| `lib.mkDefault` | 1000 | Soft default, easily overridden |
| *(bare value)* | 100 | Normal assignment |
| `lib.mkForce` | 50 | Override everything else |

For list merging:

| Function | Effect |
|---|---|
| `lib.mkBefore` | Prepend to list |
| `lib.mkAfter` | Append to list |

## DAG Ordering (Home Manager Activation Scripts)

```nix
home.activation.myScript = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  # runs after Home Manager writes files
  run echo "activating"
'';
```

Common ordering: `writeBoundary` -> `generateSshKeys` -> `ensurePubKeys`.

## Platform Conditionals

```nix
# Conditional list items
home.packages = with pkgs; [
  ripgrep
] ++ lib.optionals pkgs.stdenv.isDarwin [
  darwin-only-pkg
] ++ lib.optionals pkgs.stdenv.isLinux [
  linux-only-pkg
];

# Conditional attrsets
config = lib.mkIf pkgs.stdenv.isDarwin {
  # only evaluated on macOS
};
```

## JSON/Config File Generation

```nix
# Inline JSON
home.file.".config/app/config.json".text = builtins.toJSON {
  key = "value";
  nested.attr = true;
};

# From a source file
home.file.".config/app/config.toml".source = ./config.toml;
```

## Let Bindings

```nix
let
  name = "value";
  helper = x: x + 1;
in
{
  # use name and helper here
}
```

`let` bindings are the only way to define local variables. They are NOT recursive by default but can reference earlier bindings.

## Common Antipatterns

- **`with pkgs;` at module level** — obscures where names come from; prefer `pkgs.name` or scoped `with`
- **`rec { }` attrsets** — use `let` bindings instead; `rec` causes infinite recursion surprises
- **String interpolation for paths** — `"${./file}"` copies to store; use `./file` directly for `source`
- **Forgetting `...` in module args** — causes "unexpected argument" errors
- **Using `//` (merge) when you need `lib.mkMerge`** — `//` silently drops nested attrs; `mkMerge` deep-merges
