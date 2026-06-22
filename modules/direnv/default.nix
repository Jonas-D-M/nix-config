# modules/direnv/default.nix
# direnv with nix-direnv, integrated into zsh.
{ ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    silent = true;
  };
}
