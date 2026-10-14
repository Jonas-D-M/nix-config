# modules/home/linearmouse/default.nix
# Darwin-only HM module: seeds the default LinearMouse config. Imported only by
# hosts/darwin. Companion to modules/darwin/linearmouse.nix (Homebrew/trackpad).
#
# Launch-at-login is deliberately NOT managed here. A launchd agent that execs
# /Applications/LinearMouse.app/Contents/MacOS/LinearMouse makes TCC attribute
# the Accessibility request to the *responsible process* — the Nix-store bash
# running the wrapper script — instead of to LinearMouse.app. The grant given in
# System Settings then never matches, and because the store path changes on
# every rebuild the app re-prompts after each `drb`. LinearMouse ships its own
# login item (Contents/Library/LoginItems/LaunchAtLoginHelper.app), which is
# launched via LaunchServices and keeps its permission; enable it once in the
# app's settings.
{
  config,
  lib,
  ...
}:
let
  defaultConfigSrc = ./config.json;
in
{
  config = {
    # Seed default config if user doesn't have one yet
    home.activation.ensureLinearmouseConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CONFIG_DIR="${config.home.homeDirectory}/.config/linearmouse"
      CONFIG_FILE="$CONFIG_DIR/linearmouse.json"
      if [ ! -f "$CONFIG_FILE" ]; then
        mkdir -p "$CONFIG_DIR"
        echo "Copying default LinearMouse config to $CONFIG_FILE"
        cp "${defaultConfigSrc}" "$CONFIG_FILE"
      fi
    '';
  };
}
