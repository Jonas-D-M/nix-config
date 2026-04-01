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
}
