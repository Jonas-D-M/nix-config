# hosts/darwin/system.nix
# macOS system preferences: UI defaults, Touch ID, power, startup chime.
{ ... }:
{
  # renamed path for Touch ID
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

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
        appswitcher-all-displays = false;
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
        AppleShowAllFiles = true;
        FXPreferredViewStyle = "Nlsv";
        ShowPathbar = true;
      };
      trackpad = {
        Clicking = true;
        FirstClickThreshold = 0;
      };
      loginwindow.GuestEnabled = false;
    };
  };

  power.sleep = {
    computer = "never"; # keep the Mac awake when on power
    display = "never"; # prevent screen sleep
    harddisk = "never"; # avoid spinning down disks
  };

  power.restartAfterFreeze = true;
}
