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

  home.packages = lib.mkAfter (
    with pkgs;
    [
      docker
    ]
  );
}
