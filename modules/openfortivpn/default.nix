# modules/openfortivpn.nix
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
    enable = lib.mkEnableOption "install openfortivpn and write a default config";

    # Where to write the config: system (/etc) or user (~/.openfortivpn/config)
    scope = lib.mkOption {
      type = lib.types.enum [
        "system"
        "user"
      ];
      default = "user";
      description = "Write config to /etc/openfortivpn/config (system) or ~/.openfortivpn/config (user).";
    };

    # Required only when scope = "user"
    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Username for per-user config (required when scope = \"user\").";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.openfortivpn;
      description = "The openfortivpn package to install.";
    };

    content = lib.mkOption {
      type = lib.types.lines;
      default = defaultTemplate;
      description = "Config file content to write.";
    };
  };

  config = lib.mkIf cfg.enable (
    if cfg.scope == "system" then
      {
        # Install the binary
        environment.systemPackages = [ cfg.package ];

        # /etc/openfortivpn/config (owned by root)
        environment.etc."openfortivpn/config".text = cfg.content;
      }
    else
      # Per-user via Home Manager
      lib.mkIf (cfg.user != null) {
        # Make sure the package is available for the user as well
        home-manager.users.${cfg.user} =
          { ... }:
          {
            home.packages = [ cfg.package ];
            home.activation.ensureOpenfortivpnConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              CONFIG_PATH="$HOME/.openfortivpn/config"
              if [ ! -f "$CONFIG_PATH" ]; then
                mkdir -p "$(dirname "$CONFIG_PATH")"
                cat > "$CONFIG_PATH" <<'EOF'
                ### configuration file for openfortivpn, see man openfortivpn(1) ###
                # host = vpn.example.org
                # port = 443
                # username = vpnuser
                # password = VPNpassw0rd
                EOF
                echo "Created default openfortivpn config at $CONFIG_PATH"
              else
                echo "Preserving existing openfortivpn config"
              fi
            '';
          };
      }
  );
}
