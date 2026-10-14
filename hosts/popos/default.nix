# hosts/popos/default.nix
# The Pop!_OS host (standalone Home Manager). Desktop (GNOME/dconf) settings
# and wallpaper live in ./desktop.nix.
{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./desktop.nix
  ];

  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;

  # Weekly GC of user generations older than 30 days (systemd user timer).
  # There is no system-level Nix config on this host, so this only covers
  # the user's profiles; `nix-cleanup` still runs the same GC by hand.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  home.packages = lib.mkAfter (
    with pkgs;
    [
      docker
    ]
  );
}
