# modules/gh/default.nix
# GitHub CLI, configured to use SSH for git operations.
{ ... }:
{
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };
}
