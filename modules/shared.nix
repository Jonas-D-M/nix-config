# modules/shared.nix
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.custom;

  baseHomePackages = with pkgs; [
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
    # clockify -> doesn't work on macOS
    openfortivpn
  ];
in
{
  # This module is imported under: home-manager.users.jonas.imports = [ ./modules/shared.nix ];
  # So define ONLY user-level options here.

  imports = [
    ./zsh.nix
    ./wezterm
    ./ssh/ssh-sign.nix
    ./ssh/ssh-gen.nix
    ./git.nix
  ];

  # Provide a small API to override/extend from the host file.
  options.custom = {
    user = lib.mkOption {
      type = lib.types.str;
      example = "jonas";
      default = "jonas";
      description = "Primary username for Home Manager profile.";
    };

    extraSystemPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = [ pkgs.unzip ];
    };

    extraHomePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = [ pkgs.ripgrep ];
      description = "Additional per-host Home Manager packages to append.";
    };

    stateVersion = lib.mkOption {
      type = lib.types.str;
      default = "25.05";
      example = "25.05";
      description = "Base state version for both system/home unless overridden.";
    };

    homeStateVersion = lib.mkOption { default = config.custom.stateVersion; };
    systemStateVersion = lib.mkOption { default = config.custom.stateVersion; };
  };

  config = {
    # User-level config only
    home.stateVersion = cfg.homeStateVersion;
    programs.home-manager.enable = true;

    # Merge base + per-host extras
    home.packages = baseHomePackages ++ cfg.extraHomePackages;

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      silent = true;
    };

    programs.kubeswitch = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.k9s.enable = true;

    home.activation.createWorkDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "$HOME/work" ]; then
        echo "Creating ~/work directory..."
        mkdir -p "$HOME/work"
      fi
    '';
  };
}
