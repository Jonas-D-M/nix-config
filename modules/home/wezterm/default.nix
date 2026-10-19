# modules/home/wezterm/default.nix
# WezTerm config from ./wezterm.lua. On macOS the app comes from Homebrew, so
# the Nix package is stubbed out and only the config is managed; shell
# integration is sourced from the app bundle instead of the package.
{
  config,
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
    # Home Manager's integration is unconditional; sourced from the zsh
    # interactive layer instead.
    enableZshIntegration = false;
    extraConfig = builtins.readFile ./wezterm.lua;
  };

  custom.zsh.interactiveInit =
    if isDarwin then
      ''
        if [[ -r /Applications/WezTerm.app/Contents/Resources/wezterm.sh ]]; then
          source /Applications/WezTerm.app/Contents/Resources/wezterm.sh
        fi
      ''
    else
      ''
        source "${config.programs.wezterm.package}/etc/profile.d/wezterm.sh"
      '';
}
