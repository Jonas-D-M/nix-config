{
  pkgs,
  lib,
  ...
}:
{
  programs.wezterm = {
    enable = true;
    package = lib.mkIf pkgs.stdenv.isDarwin (lib.mkForce pkgs.emptyDirectory);
    enableZshIntegration = !pkgs.stdenv.isDarwin;
    extraConfig = builtins.readFile ./wezterm.lua;
  };
}
