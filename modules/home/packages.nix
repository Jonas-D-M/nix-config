# modules/home/packages.nix
# Base package list for every host. Hosts append their own with
# `home.packages = lib.mkAfter [ ... ];`.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
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

    # code analysis (LOC / complexity metrics)
    scc
    python3Packages.lizard

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
}
