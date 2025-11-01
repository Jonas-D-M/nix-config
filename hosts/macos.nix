# hosts/macos.nix
{ config, pkgs, ... }:
{
  # Basic nix-darwin settings
  services.nix-daemon.enable = true;
  programs.zsh.enable = true; # default macOS shell
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Example: set your hostname, enable TouchID for sudo, etc.
  networking = {
    computerName = "Jonas's MacBook Pro";
    hostName = "Jonas-MacBook-Pro";
    localHostName = "jonas-mac"; # used for Bonjour (e.g. jonas-mac.local)
  };
  security.pam.enableSudoTouchIdAuth = true;

  # Example: sensible defaults for macOS (tweak as you like)
  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.AppleShowAllExtensions = true;
  };

  # Example: packages that are macOS-only (leave cross-platform stuff in home.nix)
  environment.systemPackages = with pkgs; [
    # macOS-specific tools
    # terminal-notifier
  ];

  # Optional: Homebrew layer managed by nix-darwin (if you still want casks)
  homebrew = {
    enable = false; # set true if you want it
    onActivation.cleanup = "zap";
    taps = [ "homebrew/cask" ];
    casks = [
      # "raycast"
      # "visual-studio-code"
    ];
  };
}
