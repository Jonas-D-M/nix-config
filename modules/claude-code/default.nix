{ pkgs, lib, ... }:
let
  playSound =
    if pkgs.stdenv.isDarwin then
      "afplay /System/Library/Sounds/Glass.aiff"
    else
      "${lib.getExe' pkgs.pulseaudio "paplay"} /run/current-system/sw/share/sounds/freedesktop/stereo/complete.oga";

  settings = {
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
  };
in
{
  home.packages = [ pkgs.claude-code ];
  home.file.".claude/settings.json".text = builtins.toJSON settings;
}
