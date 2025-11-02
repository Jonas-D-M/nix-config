{ pkgs, lib, ... }:
{
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  imports = [
    ./zsh.nix
    ./wezterm
    ./ssh/ssh-sign.nix
    ./ssh/ssh-gen.nix
    ./git.nix
  ];

  home.packages = with pkgs; [
    nixfmt-rfc-style
    # essentials
    git
    curl
    wget
    gnupg
    unzip
    zip
    p7zip
    jq
    yq
    ripgrep


    # containers / k8s
    kubectl
    kubernetes-helm

    # extras
    krew
    jetbrains-mono

    # programs
    # clockify -> doesnt work on macos
    openfortivpn
    slack
  ];

  programs.kubeswitch = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.k9s = {
    enable = true;
  };

  home.activation.createWorkDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/work" ]; then
      echo "Creating ~/work directory..."
      mkdir -p "$HOME/work"
    fi
  '';
}
