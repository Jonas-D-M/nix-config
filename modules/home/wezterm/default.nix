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
