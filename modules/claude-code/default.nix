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
  home.file =
    let
      mkSkill = name: {
        ".claude/skills/${name}/SKILL.md".source = ./skills/${name}/SKILL.md;
      };
      mkCommand = name: {
        ".claude/commands/${name}/SKILL.md".source = ./commands/${name}/SKILL.md;
      };
    in
    {
      ".claude/settings.json".text = builtins.toJSON settings;
      ".claude/agents/nix-doctor.md".source = ./agents/nix-doctor.md;
    }
    // mkSkill "nix-flake-patterns"
    // mkSkill "home-manager-modules"
    // mkSkill "darwin-nix-system"
    // mkCommand "nix-check"
    // mkCommand "new-module";
}
