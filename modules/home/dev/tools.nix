# modules/home/dev/tools.nix
# Dev tools that don't belong to one stack.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    just

    # code analysis (LOC / complexity metrics)
    scc
    python3Packages.lizard

    mysql84 # client for project databases
    codex
    platformio
  ];
}
