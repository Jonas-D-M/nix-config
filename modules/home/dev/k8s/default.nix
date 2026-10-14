# modules/home/dev/k8s/default.nix
# Kubernetes CLIs plus the k9s and kubeswitch program configs.
{ pkgs, config, ... }:
{
  imports = [
    ./k9s.nix
    ./kubeswitch.nix
  ];

  home.packages = with pkgs; [
    kubectl
    krew
    kubernetes-helm # tests skipped by overlays/kubernetes-helm-skip-tests.nix
  ];

  home.sessionVariables.KUBECONFIG = "${config.home.homeDirectory}/.config/kube/config";
}
