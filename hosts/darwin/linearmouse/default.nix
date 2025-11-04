{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.linearmouse;
  user = config.system.primaryUser;
in
{
  options.services.linearmouse = {
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
          "/Applications/LinearMouse.app/Contents/MacOS/LinearMouse"
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
