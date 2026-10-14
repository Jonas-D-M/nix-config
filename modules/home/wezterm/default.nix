# modules/home/wezterm/default.nix
# WezTerm config from ./wezterm.lua. On macOS the app comes from Homebrew, so
# the Nix package is stubbed out and only the config is managed; shell
# integration is sourced from the app bundle instead of the package.
{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  programs.wezterm = {
    enable = true;
    package = lib.mkIf isDarwin (lib.mkForce pkgs.emptyDirectory);
    enableZshIntegration = !isDarwin;
    extraConfig = builtins.readFile ./wezterm.lua;
  };

  programs.zsh.initContent = lib.mkIf isDarwin ''
    if [[ -r /Applications/WezTerm.app/Contents/Resources/wezterm.sh ]]; then
      source /Applications/WezTerm.app/Contents/Resources/wezterm.sh
    fi
  '';
}
