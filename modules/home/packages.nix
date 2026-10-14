# modules/home/packages.nix
# Machine basics for every host, independent of dev work (that lives in ./dev).
# Hosts append their own with `home.packages = lib.mkAfter [ ... ];`.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nixfmt

    # essentials
    curl
    wget
    gnumake
    unzip
    zip
    p7zip
    jq
    yq-go
    ripgrep
    pv
    fastfetch

    # secrets (SOPS_AGE_KEY_FILE is set in ./default.nix)
    gnupg
    sops
    age
    pass
  ];
}
