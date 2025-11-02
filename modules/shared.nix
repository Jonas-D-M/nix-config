{ pkgs, lib, ... }:
{
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  imports = [
    ./zsh.nix
    ./wezterm
    # ./ssh/ssh-sign.nix
    # ./ssh/ssh-gen.nix
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

    openssh

    # containers / k8s
    kubectl
    kubernetes-helm

    # extras
    krew
    jetbrains-mono

    # programs
    vscode
    spotify
    dbeaver-bin
    # clockify -> doesnt work on macos
    google-chrome
    postman
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

  home.activation.ensureLaunchAgentsDir = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [ "$(uname -s)" = "Darwin" ]; then
      mkdir -p "$HOME/Library/LaunchAgents"
      chown "$USER":staff "$HOME/Library/LaunchAgents" 2>/dev/null || true
      chmod 755 "$HOME/Library" "$HOME/Library/LaunchAgents" 2>/dev/null || true
    fi
  '';
}
