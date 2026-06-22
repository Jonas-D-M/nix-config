# modules/darwin/linearmouse/default.nix
# System-level (nix-darwin): Homebrew install + trackpad defaults.
# Companion to ./home.nix (the Home Manager LaunchAgent module).
{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.services.linearmouse;
in
{
  options.custom.services.linearmouse = {
    enable = lib.mkEnableOption "LinearMouse (install via Homebrew + natural scroll)";
  };

  config = lib.mkIf cfg.enable {
    homebrew.enable = true;
    homebrew.casks = lib.mkAfter [ "linearmouse" ];

    # Keep trackpad 'natural'
    system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = true;
  };
}
