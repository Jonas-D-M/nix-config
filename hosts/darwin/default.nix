{ pkgs, lib, ... }:
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

  system = {
    startup.chime = false;
    defaults = {
      CustomUserPreferences = {
        "com.apple.Siri" = {
          StatusMenuVisible = false; # hide Siri icon
        };

      };
      controlcenter = {
        BatteryShowPercentage = true;
      };
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.trackpad.forceClick" = false;
      };
      dock = {
        autohide = true;
        showhidden = true;
        show-recents = false;
        static-only = false;
        launchanim = false;
        mineffect = "scale";
        appswitcher-all-displays = true;
        minimize-to-application = true;
        persistent-apps = [
          "/Applications/Google Chrome.app"
          "/Applications/Visual Studio Code.app"
          "/Applications/Spotify.app"
          "/Applications/Microsoft Teams.app"
          "/Applications/WezTerm.app"
          "/Applications/DBeaver.app"
          "/Applications/Clockify Desktop.app"
          "/Applications/Microsoft Outlook.app"
          "/Applications/Slack.app"
        ];
        persistent-others = [ ];
      };
      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
      };
      trackpad = {
        Clicking = true;
        FirstClickThreshold = 0;
      };
      loginwindow.GuestEnabled = false;
    };

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
      "microsoft-teams"
      "clockify"
      "slack"
      "microsoft-outlook"
      "font-jetbrains-mono-nerd-font"
    ];
    onActivation.cleanup = "zap";
  };

  power.sleep = {
    computer = "never"; # keep the Mac awake when on power
    display = "never"; # prevent screen sleep
    harddisk = "never"; # avoid spinning down disks
  };

  power.restartAfterFreeze = true;

  home-manager.users.jonas = {
    custom.extraHomePackages = with pkgs; [
      colima
      docker
      docker-compose
    ];

  };

}
