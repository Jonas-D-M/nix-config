{ pkgs, lib, ... }:
{
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  home.activation.createWorkDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/work" ]; then
      echo "Creating ~/work directory..."
      mkdir -p "$HOME/work"
    fi
  '';

  imports = [
    ./zsh.nix
    ./wezterm.nix
    ./git-ssh-sign.nix
    ./secrets.nix
  ];


  home.packages = with pkgs; [
    nixfmt-rfc-style
    # essentials
    git gh curl wget gnupg
    unzip zip p7zip
    jq yq
    eza ripgrep fzf zoxide tree

    # tools we used for secrets
    age sops

    # containers / k8s
    kubectl kubectx kubernetes-helm k9s stern

    # extras
    krew
    jetbrains-mono

    # programs
    vscode

  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.shellAliases = {
    dps  = "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'";
    sail = "bash vendor/bin/sail";
  };
}