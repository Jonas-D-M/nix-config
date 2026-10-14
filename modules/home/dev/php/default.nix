# modules/home/dev/php/default.nix
# Global PHP toolchain for ad-hoc use; project flakes pin their own versions.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    php83
    php83Packages.composer
  ];
}
