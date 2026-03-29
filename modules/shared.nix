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
    nixfmt

    # essentials
    curl
    wget
    gnupg
    unzip
    zip
    p7zip
    jq
    yq-go
    ripgrep

    # Dev
    php83
    php83Packages.composer
    bun

    # containers / k8s
    kubectl
    kubernetes-helm

    # extras
    krew
    fastfetch
    sops
    age
    pass

    # programs
    mysql80

  ];
in
{
  # This module is imported under: home-manager.users.jonas.imports = [ ./modules/shared.nix ];
  # So define ONLY user-level options here.

  imports = [
    ./zsh
    ./git
    ./wezterm
    ./openfortivpn
    ./ssh
    ./ralph
    ./claude-code
    ./k9s
    ./node
    ./colima
    ./linearmouse
    ./vscode
  ];

  # Provide a small API to override/extend from the host file.
  options.custom = {
    user = lib.mkOption {
      type = lib.types.str;
      example = "jonas";
      default = "jonas";
      description = "Primary username for Home Manager profile.";
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

    homeStateVersion = lib.mkOption {
      type = lib.types.str;
      default = config.custom.stateVersion;
    };
    systemStateVersion = lib.mkOption {
      type = lib.types.str;
      default = config.custom.stateVersion;
    };
  };

  config = {
    xdg.enable = true;

    # User identity
    home.username = cfg.user;
    home.homeDirectory =
      if pkgs.stdenv.isDarwin then "/Users/${cfg.user}" else "/home/${cfg.user}";
    news.display = "silent";

    # User-level config only
    home.stateVersion = cfg.homeStateVersion;
    home.sessionVariables = {
      KUBECONFIG = "$HOME/.config/kube/config";
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    };
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

    home.activation.createWorkDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "$HOME/work" ]; then
        echo "Creating ~/work directory..."
        mkdir -p "$HOME/work"
      fi
    '';
    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
      };
    };

    programs.openfortivpn = {
      enable = true;
      createAlias = true;
    };
  };
}
