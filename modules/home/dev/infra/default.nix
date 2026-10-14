# modules/home/dev/infra/default.nix
# Infrastructure-as-code and secret-store CLIs.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    opentofu
    openbao
  ];
}
