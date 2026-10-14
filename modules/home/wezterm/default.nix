# modules/home/wezterm/default.nix
# WezTerm config from ./wezterm.lua. On macOS the app comes from Homebrew, so
# the Nix package is stubbed out and only the config is managed.
{
  pkgs,
  lib,
  ...
}:
{
  programs.wezterm = {
    enable = true;
    package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (lib.mkForce pkgs.emptyDirectory);
    enableZshIntegration = !pkgs.stdenv.hostPlatform.isDarwin;
    extraConfig = builtins.readFile ./wezterm.lua;
  };
}
