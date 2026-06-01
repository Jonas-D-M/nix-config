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

  vpnModule = lib.types.submodule (
    { name, ... }:
    {
      options = {
        configFile = lib.mkOption {
          type = lib.types.str;
          default = ".config/openfortivpn/${name}";
          description = "Config file path relative to $HOME.";
        };

        content = lib.mkOption {
          type = lib.types.lines;
          default = defaultTemplate;
          description = "Template content for first-time config creation.";
        };
      };
    }
  );
in
{
  options.programs.openfortivpn = {
    enable = lib.mkEnableOption "Install openfortivpn and seed user configs once";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.openfortivpn;
      description = "openfortivpn package to install.";
    };

    defaultConfig = lib.mkOption {
      type = lib.types.str;
      default = ".config/openfortivpn/config";
      description = "Path (relative to $HOME) used when 'vpn' is invoked with no arguments.";
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = ".config/openfortivpn";
      description = "Directory (relative to $HOME) searched when 'vpn <name>' is invoked.";
    };

    installFunction = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the 'vpn' shell function that dispatches to configs by name.";
    };

    vpns = lib.mkOption {
      type = lib.types.attrsOf vpnModule;
      default = { };
      description = "Named VPN configurations to seed on first activation.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.activation.ensureOpenfortivpnConfigs = lib.mkIf (cfg.vpns != { }) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: vpn: ''
            CONFIG_PATH="$HOME/${vpn.configFile}"
            if [ ! -f "$CONFIG_PATH" ]; then
              mkdir -p "$(dirname "$CONFIG_PATH")"
              cat > "$CONFIG_PATH" <<'EOF'
            ${vpn.content}
            EOF
              echo "Created default openfortivpn config (${name}) at $CONFIG_PATH"
            else
              echo "Preserving existing openfortivpn config (${name}) at $CONFIG_PATH"
            fi
          '') cfg.vpns
        )
      )
    );

    programs.zsh.initContent = lib.mkIf cfg.installFunction ''
      vpn() {
        local default_config="$HOME/${cfg.defaultConfig}"
        local config_dir="$HOME/${cfg.configDir}"
        local config

        if [ $# -eq 0 ]; then
          config="$default_config"
        elif [ -f "$config_dir/$1" ]; then
          config="$config_dir/$1"
        elif [ -f "$1" ]; then
          config="$1"
        else
          print -u2 "vpn: no config found for '$1'"
          if [ -d "$config_dir" ]; then
            print -u2 "available configs in $config_dir:"
            ls -1 "$config_dir" >&2
          fi
          return 1
        fi

        sudo openfortivpn -c "$config"
      }

      _vpn() {
        local config_dir="$HOME/${cfg.configDir}"
        if [ -d "$config_dir" ]; then
          local -a configs
          configs=("$config_dir"/*(N:t))
          _describe 'openfortivpn config' configs
        fi
      }
      compdef _vpn vpn
    '';
  };
}
