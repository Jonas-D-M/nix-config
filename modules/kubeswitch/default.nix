# modules/kubeswitch/default.nix
# kubeswitch: fast kubeconfig context switching, integrated into zsh.
{ ... }:
{
  programs.kubeswitch = {
    enable = true;
    enableZshIntegration = true;
  };
}
