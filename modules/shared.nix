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
    gnumake
    unzip
    zip
    p7zip
    jq
    yq-go
    ripgrep
    pv

    # Dev
    php83
    php83Packages.composer
    bun
    nodejs
    just
    opentofu
    openbao

    # containers / k8s
    kubectl
    # kubernetes-helm's checkPhase has failed to build in this nixpkgs line, so
    # its tests are disabled here as a workaround. Re-verify on nixpkgs bumps:
    # try dropping this overrideAttrs and `nix build nixpkgs#kubernetes-helm`.
    (kubernetes-helm.overrideAttrs (_: {
      doCheck = false;
    }))

    # extras
    krew
    fastfetch
    sops
    age
    pass

    # programs
    mysql84

    codex
    platformio
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
    ./kubeswitch
    ./node
    ./gh
    ./direnv
    ./colima
    ./linearmouse
    ./neovim
    ./vscode
    ./rtk
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
  };

  config = {
    xdg.enable = true;

    # User identity
    home.username = cfg.user;
    home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${cfg.user}" else "/home/${cfg.user}";
    news.display = "silent";

    # User-level config only
    home.stateVersion = cfg.homeStateVersion;
    home.sessionVariables = {
      KUBECONFIG = "${config.home.homeDirectory}/.config/kube/config";
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    };
    programs.home-manager.enable = true;

    # Merge base + per-host extras
    home.packages = baseHomePackages ++ cfg.extraHomePackages;

    programs.openfortivpn = {
      enable = true;
      vpns = {
        secondary = { };
      };
    };
  };
}
