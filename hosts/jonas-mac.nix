{ pkgs, ... }:
{
  # nix-darwin owns nix-daemon
  nix.enable = true;

  # set once; keep stable
  system.stateVersion = 6;

  # must match your Mac short username
  system.primaryUser = "jonas";

  programs.zsh.enable = true;

  # renamed path for Touch ID
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking = {
    computerName = "Jonas's MacBook Pro";
    hostName = "Jonas-MacBook-Pro";
    localHostName = "jonas-mac";
  };

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
    };
    trackpad.Clicking = true;
  };

  # keep system packages empty; you install via Home Manager
  environment.systemPackages = [ ];

  homebrew = {
    enable = true;
    casks = [
      "wezterm"
      "visual-studio-code"
      "spotify"
      "google-chrome"
      "dbeaver-community"
      "postman"
    ];
    onActivation.cleanup = "zap";
  };
}
