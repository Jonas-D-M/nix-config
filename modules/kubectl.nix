{ pkgs, config, ... }:
{
  home.sessionVariables.KUBECONFIG = "$HOME/.config/kube/config";
}
