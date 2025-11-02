# modules/openfortivpn/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.openfortivpn;

  defaultTemplate = ''
    ### configuration file for openfortivpn, see man openfortivpn(1) ###

    # host = vpn.example.org
    # port = 443
    # username = vpnuser
    # password = VPNpassw0rd
    # trusted-cert = 0123456789abcdef...
  '';
in
{
  options.programs.openfortivpn = {
    enable = lib.mkEnableOption "Install openfortivpn and seed a default user config once";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.openfortivpn;
      description = "openfortivpn package to install.";
    };

    # Path relative to $HOME
    configFile = lib.mkOption {
      type = lib.types.str;
      default = ".config/openfortivpn/config";
      description = "Config file path relative to $HOME.";
    };

    # Initial file content (used only when the file doesn't exist yet)
    content = lib.mkOption {
      type = lib.types.lines;
      default = defaultTemplate;
      description = "Template content for first-time config creation.";
    };

    createAlias = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Add a 'vpn' alias that runs openfortivpn with this config.";
    };
  };

  # This is a Home Manager module: don't reference home-manager.users.* here.
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Create the file once if missing; preserve manual edits thereafter.
    home.activation.ensureOpenfortivpnConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            CONFIG_PATH="$HOME/${cfg.configFile}"
            if [ ! -f "$CONFIG_PATH" ]; then
              mkdir -p "$(dirname "$CONFIG_PATH")"
              cat > "$CONFIG_PATH" <<'EOF'
      ${cfg.content}
      EOF
              echo "Created default openfortivpn config at $CONFIG_PATH"
            else
              echo "Preserving existing openfortivpn config at $CONFIG_PATH"
            fi
    '';

    programs.zsh.shellAliases = lib.mkIf cfg.createAlias {
      vpn = "sudo openfortivpn -c \"$HOME/${cfg.configFile}\"";
    };
  };
}
