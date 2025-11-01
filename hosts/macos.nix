# hosts/macos.nix
{
  config,
  pkgs,
  lib,
  ...
}:
    # Let nix-darwin manage the nix installation & daemon. Disabling this can
    # lead to launchctl bootout/bootstrap warnings if an external installer
    # (e.g. Determinate Systems) created services with differing labels.
    # Enabling brings them under declarative control and avoids noisy errors
    # like: "boot-out failed: 3: no such process" / "Bootstrap failed: 5".
    nix.enable = true;

    # Ensure the daemon service is explicitly enabled (older configs used this).
    services.nix-daemon.enable = true;
  nix.enable = false;

  # Required with newer nix-darwin (set once and keep it)
  system.stateVersion = 6;

  # Needed because you set user-scoped system.defaults.* options
  system.primaryUser = "jonasdemeyer";

  # Declare the primary user so launchd user agents and paths resolve cleanly.
  # This prevents bootstrap errors when user contexts are missing.
  users.users.jonasdemeyer = {
    home = "/Users/jonasdemeyer";
    shell = pkgs.zsh;
  };

  # Shells
  programs.zsh.enable = true;
  programs.fish.enable = false;

  # New Touch ID option path
  security.pam.services.sudo_local.touchIdAuth = true;

  # Nix settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  # Host naming
  networking = {
    computerName = "Jonas's MacBook Pro";
    hostName = "Jonas-MacBook-Pro";
    localHostName = "jonas-mac";
  };

  # System defaults (these now apply cleanly with system.primaryUser set)
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
    dock = {
      autohide = true;
      show-recents = false;
      mru-spaces = false;
      tilesize = 48;
    };
    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      _FXShowPosixPathInTitle = true;
    };
    trackpad = {
      Clicking = true;
    };
  };

  # # System-level packages (keep lean; GUI via HM)
  # environment.systemPackages = with pkgs; [
  #   git
  #   curl
  #   wget
  #   jq
  #   ripgrep
  #   eza
  #   fzf
  #   zoxide
  #   direnv
  #   age
  #   sops
  #   bitwarden-cli
  #   openssh
  #   # terminal-notifier # <- uncomment if you want it
  # ];

  # Homebrew layer (off by default)
  homebrew = {
    enable = false;
    onActivation.cleanup = "zap";
    taps = [ "homebrew/cask" ];
    casks = [ ];
  };

  # Correct sops age key path (flake used /Users/jonas earlier). Keep mkDefault so
  # user-level overrides are still possible in other modules.
  sops.age.keyFile = lib.mkDefault "/Users/jonasdemeyer/.config/sops/age/keys.txt";
}
