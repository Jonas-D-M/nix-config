{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.profiles.linearmouse;
in
{
  options.profiles.linearmouse.enable = lib.mkEnableOption "LinearMouse setup";

  config = lib.mkIf cfg.enable {
    homebrew.enable = true;
    homebrew.casks = (config.homebrew.casks or [ ]) ++ [ "linearmouse" ];

    # # start at login as a user agent
    # launchd.user.agents.linearmouse = {
    #   enable = true;
    #   program = "/Applications/LinearMouse.app/Contents/MacOS/LinearMouse";
    #   runAtLoad = true;
    #   keepAlive = true;
    # };

    # keep global on “natural” (trackpad happy)
    system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = true;
  };
}
