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
    # kubernetes-helm's checkPhase has failed to build in this nixpkgs line, so
    # its tests are disabled here as a workaround. Re-verify on nixpkgs bumps:
    # try dropping this overrideAttrs and `nix build nixpkgs#kubernetes-helm`.
    (kubernetes-helm.overrideAttrs (_: {
      doCheck = false;
    }))
  ];

  home.sessionVariables.KUBECONFIG = "${config.home.homeDirectory}/.config/kube/config";
}
