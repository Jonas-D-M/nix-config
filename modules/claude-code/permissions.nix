{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.claudeCode;

  # Conservative: read-only operations
  baseAllow = [
    "Glob(*)"
    "Grep(*)"
    "Read(*)"
    "Task(*)"
    "TodoWrite(*)"
    "Bash(git status:*)"
    "Bash(git log:*)"
    "Bash(git diff:*)"
    "Bash(git show:*)"
    "Bash(git branch:*)"
    "Bash(git remote:*)"
    "Bash(ls:*)"
    "Bash(find:*)"
    "Bash(cat:*)"
    "Bash(head:*)"
    "Bash(tail:*)"
    "Bash(nix eval:*)"
    "Bash(nix flake show:*)"
    "Bash(nix flake metadata:*)"
    "WebFetch(domain:github.com)"
    "WebFetch(domain:raw.githubusercontent.com)"
    "WebFetch(domain:nixos.org)"
    "WebFetch(domain:wiki.nixos.org)"
  ];

  # Standard: read + write, build, dev tools
  standardAllow = baseAllow ++ [
    "Edit(*)"
    "Write(*)"
    "Bash(git add:*)"
    "Bash(git commit:*)"
    "Bash(git worktree:*)"
    "Bash(nix build:*)"
    "Bash(nix flake check:*)"
    "Bash(nix flake lock:*)"
    "Bash(nix flake update:*)"
    "Bash(nix search:*)"
    "Bash(nix run nixpkgs#:*)"
    "Bash(nix shell nixpkgs#:*)"
    "Bash(nixfmt:*)"
    "Bash(mkdir:*)"
    "Bash(chmod:*)"
    "Bash(wc:*)"
    "Bash(xargs:*)"
    "Bash(rg:*)"
    "Bash(grep:*)"
    "Bash(node:*)"
    "Bash(npm:*)"
    "Bash(npx:*)"
    "Bash(bun:*)"
    "Bash(gh status:*)"
    "Bash(gh pr list:*)"
    "Bash(gh pr view:*)"
    "Bash(gh pr checks:*)"
    "Bash(gh issue list:*)"
    "Bash(gh issue view:*)"
    "Bash(gh repo view:*)"
    "Bash(gh api:*)"
    "Bash(claude --version)"
    "WebFetch(*)"
    "WebSearch"
  ];

  # Autonomous: adds git branch operations
  autonomousAllow = standardAllow ++ [
    "Bash(git checkout:*)"
    "Bash(git switch:*)"
    "Bash(git stash:*)"
    "Bash(git restore:*)"
  ];

  # Standard ask: destructive/external operations need confirmation
  standardAsk = [
    "Bash(git push:*)"
    "Bash(git merge:*)"
    "Bash(git rebase:*)"
    "Bash(git reset:*)"
    "Bash(rm:*)"
    "Bash(cp:*)"
    "Bash(mv:*)"
    "Bash(sudo:*)"
    "Bash(darwin-rebuild:*)"
    "Bash(home-manager:*)"
    "Bash(curl:*)"
    "Bash(ssh:*)"
    "Bash(gh pr create:*)"
    "Bash(gh pr merge:*)"
    "Bash(gh pr close:*)"
    "Bash(gh issue create:*)"
    "Bash(gh issue close:*)"
  ];

  # Autonomous ask: reduced set
  autonomousAsk = [
    "Bash(git push:*)"
    "Bash(git merge:*)"
    "Bash(git rebase:*)"
    "Bash(git reset:*)"
    "Bash(rm:*)"
    "Bash(sudo:*)"
    "Bash(darwin-rebuild:*)"
    "Bash(home-manager:*)"
  ];

  # Conservative ask: everything standard can do + write ops
  conservativeAsk = standardAsk ++ standardAllow;

  denyList = [
    "Bash(rm -rf /:*)"
    "Bash(rm -rf /*:*)"
    "Bash(dd:*)"
    "Bash(mkfs:*)"
    "Bash(cat .env:*)"
    "Bash(cat .env.*:*)"
    "Bash(printenv:*)"
  ];
in
{
  options.custom.claudeCode = {
    permissionProfile = lib.mkOption {
      type = lib.types.enum [
        "conservative"
        "standard"
        "autonomous"
      ];
      default = "autonomous";
      description = ''
        Permission profile for Claude Code operations:
        - conservative: Read-only, most operations require confirmation
        - standard: Balanced permissions for normal development
        - autonomous: Maximum autonomy for trusted environments
      '';
    };

    _resolvedPermissions = lib.mkOption {
      type = lib.types.attrs;
      internal = true;
      readOnly = true;
      default = {
        allow =
          if cfg.permissionProfile == "autonomous" then
            autonomousAllow
          else if cfg.permissionProfile == "standard" then
            standardAllow
          else
            baseAllow;
        ask =
          if cfg.permissionProfile == "autonomous" then
            autonomousAsk
          else if cfg.permissionProfile == "standard" then
            standardAsk
          else
            conservativeAsk;
        deny = denyList;
      };
    };
  };
}
