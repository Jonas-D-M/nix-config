# modules/linearmouse/default.nix
# Darwin-only HM module: LaunchAgent + config seeding
{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.home.username;
  linearmouseStartScript = pkgs.writeShellScript "linearmouse-start" ''
    # Wait for WindowServer and accessibility to be ready
    sleep 5
    exec /Applications/LinearMouse.app/Contents/MacOS/LinearMouse
  '';
  defaultConfigSrc = ../darwin/linearmouse/config.json;
in
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    launchd.agents.linearmouse = {
      enable = true;
      config = {
        Label = "dev.${user}.linearmouse";
        ProgramArguments = [
          "${linearmouseStartScript}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Interactive";
        StandardOutPath = "/tmp/linearmouse.out.log";
        StandardErrorPath = "/tmp/linearmouse.err.log";
      };
    };

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
