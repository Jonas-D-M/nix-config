{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.services.linearmouse;
  user = config.system.primaryUser;
  linearmouseStartScript = pkgs.writeShellScript "linearmouse-start" ''
    # Wait for WindowServer and accessibility to be ready
    sleep 5
    exec /Applications/LinearMouse.app/Contents/MacOS/LinearMouse
  '';
in
{
  options.custom.services.linearmouse = {
    enable = lib.mkEnableOption "LinearMouse (install + natural scroll + LaunchAgent)";
    defaultConfig = lib.mkOption {
      type = lib.types.path;
      default = ./config.json;
      description = "Path to LinearMouse configuration file.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install via Homebrew without self-referencing -> no recursion
    homebrew.enable = true;
    homebrew.casks = lib.mkAfter [ "linearmouse" ];

    # Keep trackpad 'natural'
    system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = true;

    # Launch at login (Home Manager uses `config` for plist keys)
    home-manager.users.${user}.launchd.agents.linearmouse = {
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
    # Copy default config if user doesn't have one yet
    system.activationScripts.linearmouse = {
      text = ''
        CONFIG_DIR="/Users/${user}/.config/linearmouse"
        CONFIG_FILE="$CONFIG_DIR/linearmouse.json"
        mkdir -p "$CONFIG_DIR"
        if [ ! -f "$CONFIG_FILE" ]; then
          echo "Copying default LinearMouse config to $CONFIG_FILE"
          cp "${cfg.defaultConfig}" "$CONFIG_FILE"
        fi
      '';
    };
  };
}
