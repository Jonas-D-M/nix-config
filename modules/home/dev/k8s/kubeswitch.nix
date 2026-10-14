# modules/home/dev/k8s/kubeswitch.nix
# kubeswitch: fast kubeconfig context switching, integrated into zsh.
{ ... }:
{
  programs.kubeswitch = {
    enable = true;
    enableZshIntegration = true;
  };
}
