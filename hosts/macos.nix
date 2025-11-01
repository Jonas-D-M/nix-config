# hosts/macos.nix
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # nix-darwin now manages nix-daemon automatically when nix.enable = true
  nix.enable = true;

  # Required with newer nix-darwin (set once and keep it)
  system.stateVersion = 6;

  # Needed because you set user-scoped system.defaults.* options
  system.primaryUser = "jonas";

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
}
