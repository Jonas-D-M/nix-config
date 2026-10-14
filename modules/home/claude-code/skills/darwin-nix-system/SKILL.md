---
description: nix-darwin system configuration patterns. Use when modifying macOS system settings, Homebrew casks, or host-level config in hosts/darwin/.
user-invocable: false
---

# nix-darwin System Configuration

## System vs User Level Split

| Layer | Location | Manager | Scope |
|---|---|---|---|
| System | `hosts/darwin/` | nix-darwin | macOS defaults, Homebrew, PAM, networking |
| User | `modules/` | Home Manager | Dotfiles, user packages, shell config |

System-level settings require `sudo darwin-rebuild switch` (alias `drb`). User-level changes go through Home Manager.

## macOS System Defaults

Configure via `system.defaults` in `hosts/darwin/default.nix`:

```nix
system.defaults = {
  dock = {
    autohide = true;
    mru-spaces = false;          # don't rearrange spaces by recent use
    show-recents = false;
    tilesize = 48;
    persistent-apps = [ ];       # clear default dock icons
  };

  finder = {
    AppleShowAllExtensions = true;
    FXPreferredViewStyle = "Nlsv";  # list view
    ShowPathbar = true;
  };

  NSGlobalDomain = {
    AppleShowAllExtensions = true;
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    "com.apple.swipescrolldirection" = false;  # natural scrolling off
  };

  trackpad = {
    Clicking = true;             # tap to click
    TrackpadRightClick = true;
  };
};
```

These map to `defaults write` commands. Changes apply on next `drb`.

## Homebrew Cask Management

```nix
homebrew = {
  enable = true;
  onActivation = {
    cleanup = "zap";    # remove casks not listed here
    autoUpdate = true;
    upgrade = true;
  };
  casks = [
    "firefox"
    "wezterm"
    "raycast"
  ];
  brews = [
    "some-formula"
  ];
};
```

`cleanup = "zap"` is aggressive — it removes casks AND their preferences. Only listed casks survive activation.

## Touch ID for sudo

```nix
security.pam.services.sudo_local = {
  touchIdAuth = true;
};
```

## System Identity

```nix
system.primaryUser = "jonas";
networking.hostName = "jonas-mac";
networking.computerName = "jonas-mac";
```

## Power and Performance

```nix
power.sleep = {
  display = 10;    # minutes
  computer = 0;    # never
};
```

## Build Commands

| Action | Command | Alias |
|---|---|---|
| Apply | `sudo darwin-rebuild switch --flake ~/nix-config` | `drb` |
| Dry-run | `nix build .#darwinConfigurations.jonas-mac.system` | -- |
| Check eval | `nix flake check` | -- |

Always dry-run before applying system changes to catch evaluation errors early.
