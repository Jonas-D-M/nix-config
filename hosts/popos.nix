# hosts/popos.nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # sync the wallpaper directory from your repo to ~/.local/share/backgrounds/w11
  wallpaperDir = "${config.home.homeDirectory}/.local/share/backgrounds/w11";

  wallpaperFile = "${wallpaperDir}/img22.jpg";

  wallpaperUri = "file://${wallpaperFile}";
in
{
  home.file.".local/share/backgrounds/w11" = {
    source = ../media/wallpapers/w11;
    recursive = true;
  };

  home.packages = lib.mkAfter (
    with pkgs;
    [
      docker
    ]
  );
  dconf.settings = {
    # Theme preference override (Pop defaults to dark)
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-light";
      show-battery-percentage = true;
    };

    # Wallpaper and lock screen background
    "org/gnome/desktop/background" = {
      picture-uri = "file://${wallpaperFile}";
      picture-uri-dark = "file://${wallpaperFile}";
      picture-options = "zoom";
    };
    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${wallpaperFile}";
      lock-enabled = false;
    };

    # Pop Shell / tiling tweaks
    "org/gnome/shell/extensions/pop-shell" = {
      active-hint = false;
      tile-by-default = false;
      focus-right = [
        "<Super>Right"
        "<Super>KP_Right"
      ];
    };

    # COSMIC behavior changes
    "org/gnome/shell/extensions/pop-cosmic" = {
      show-applications-button = false;
      show-workspaces-button = true;
    };

    # App favorites
    "org/gnome/shell" = {
      favorite-apps = [
        "google-chrome.desktop"
        "org.gnome.Nautilus.desktop"
        "code.desktop"
        "spotify.desktop"
        "teams-for-linux.desktop"
        "org.wezfurlong.wezterm.desktop"
        "dbeaver-ce.desktop"
        "clockify.desktop"
        "chrome-faolnafnngnfdaknnbpnkhgohbobgegn-Default.desktop"
        "slack.desktop"
      ];
    };

    # Keyboard shortcuts
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/PopLaunch1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
      terminal = [
        "<Super>t"
        "<Primary><Alt>t"
      ];
      screensaver = [ "<Super>l" ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/PopLaunch1" = {
      name = "WiFi";
      command = "gnome-control-center wifi";
      binding = "Launch1";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "System monitor";
      command = "gnome-system-monitor";
      binding = "<Primary><Shift>Escape";
    };

    # Touchpad override (natural scroll ON)
    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = true;
      two-finger-scrolling-enabled = true;
      disable-while-typing = false;
    };

    # Power management (prevent suspend on AC)
    "org/gnome/settings-daemon/plugins/power" = {
      idle-dim = false;
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "suspend";
    };

    # Window manager tweaks
    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-down = [
        "<Primary><Super>KP_Down"
        "<Primary><Super>j"
      ];
      switch-to-workspace-up = [
        "<Primary><Super>KP_Up"
        "<Primary><Super>k"
      ];
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };

    # GNOME terminal default (Pop uses Tilix, so this overrides to WezTerm)
    "org/gnome/desktop/applications/terminal" = {
      exec = "wezterm";
    };

    # System tweaks
    "org/gnome/desktop/sound" = {
      allow-volume-above-100-percent = true;
    };
  };
}
