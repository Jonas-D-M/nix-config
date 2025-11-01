{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Combined Darwin host-specific settings (merged duplicate blocks).
  services.nix-daemon.enable = true;
  programs.zsh.enable = true;
  programs.fish.enable = false;
  security.pam.enableSudoTouchIdAuth = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  # Host naming (computerName used for UI; host/local host names for networking).
  networking = {
    computerName = "Jonas's MacBook Pro";
    hostName = "Jonas-MacBook-Pro";
    localHostName = "jonas-mac";
  };

  # System defaults consolidated (retain extended settings from first block + second block additions).
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

  # System-level packages (keep lean; GUI/apps via Home Manager or Homebrew if enabled).
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    jq
    ripgrep
    eza
    fzf
    zoxide
    direnv
    age
    sops
    bitwarden-cli
    openssh
    # Add macOS-only tools below (uncomment as needed):
    # terminal-notifier
  ];

  # Homebrew layer disabled by default (enable if you need casks not yet in nixpkgs).
  homebrew = {
    enable = false;
    onActivation.cleanup = "zap";
    taps = [ "homebrew/cask" ];
    casks = [ ];
  };
}
