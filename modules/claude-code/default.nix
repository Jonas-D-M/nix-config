{
  config,
  pkgs,
  lib,
  ...
}:
let
  playSound =
    if pkgs.stdenv.isDarwin then
      "afplay /System/Library/Sounds/Glass.aiff"
    else
      "${lib.getExe' pkgs.pulseaudio "paplay"} /run/current-system/sw/share/sounds/freedesktop/stereo/complete.oga";

  settings = {
    model = "claude-opus-4-6";
    hooks = {
      Stop = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = playSound;
            }
          ];
        }
      ];
    };
    sandbox = {
      enabled = true;
      excludedCommands = [
        "nix:*"
        "nix-build:*"
        "nix-shell:*"
        "nix-instantiate:*"
        "darwin-rebuild:*"
        "home-manager:*"
        "brew:*"
      ];
      filesystem = {
        allowWrite = [ "." ];
        denyRead = [
          ".env"
          ".env.local"
          ".env.development"
          ".env.production"
          ".env.staging"
          ".env.test"
          "/etc/shadow"
        ];
      };
      network = {
        allowedDomains = [ "*" ];
      };
    };
    permissions = config.custom.claudeCode._resolvedPermissions;
  };
in
{
  imports = [ ./permissions.nix ];

  home.packages = [ pkgs.claude-code ];
  home.file.".claude/settings.json".text = builtins.toJSON settings;

  # Skills
  home.file.".claude/skills/nix-flake-patterns/SKILL.md".source =
    ./skills/nix-flake-patterns/SKILL.md;
  home.file.".claude/skills/home-manager-modules/SKILL.md".source =
    ./skills/home-manager-modules/SKILL.md;
  home.file.".claude/skills/darwin-nix-system/SKILL.md".source = ./skills/darwin-nix-system/SKILL.md;

  # Commands
  home.file.".claude/commands/nix-check/SKILL.md".source = ./commands/nix-check/SKILL.md;
  home.file.".claude/commands/new-module/SKILL.md".source = ./commands/new-module/SKILL.md;

  # Agents
  home.file.".claude/agents/nix-doctor.md".source = ./agents/nix-doctor.md;
}
