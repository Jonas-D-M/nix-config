# modules/k9s/default.nix
{ ... }:
{
  programs.k9s = {
    enable = true;

    settings.k9s.ui.skin = "transparent";

    skins.transparent = ./transparent.yaml;
  };
}
