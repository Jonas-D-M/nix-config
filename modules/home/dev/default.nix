# modules/home/dev/default.nix
# Dev-work tooling, one module per stack. Everything a machine needs regardless
# of work (core CLI, secrets tooling, shell, git, ssh, editors) lives outside
# dev/, with base packages in ../packages.nix.
{ ... }:
{
  imports = [
    ./infra
    ./k8s
    ./node
    ./php
    ./tools.nix
  ];
}
