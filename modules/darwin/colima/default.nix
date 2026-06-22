# modules/darwin/colima/default.nix
# Darwin-only HM module: Colima Docker runtime + launchd auto-start.
# Imported via hosts/darwin's home-manager.users (not shared.nix).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.services.colima;
  user = config.home.username;
  diskFlag = lib.optionalString (cfg.disk != null) " --disk ${toString cfg.disk}";
  sshAgentFlag = lib.optionalString cfg.sshAgent " --ssh-agent";
  colimaStartScript = pkgs.writeShellScript "colima-start" ''
    # Clean up stale VM state from unclean shutdown before starting.
    # Stopping first lets `start` apply changed --cpus/--memory to the existing VM.
    ${pkgs.colima}/bin/colima stop --force 2>/dev/null || true
    exec ${pkgs.colima}/bin/colima start --foreground \
      --cpus ${toString cfg.cpu} \
      --memory ${toString cfg.memory}${diskFlag}${sshAgentFlag}
  '';
in
{
  options.custom.services.colima = {
    enable = lib.mkEnableOption "Colima (Docker runtime via Lima VM + auto-start)";

    socketPath = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${config.home.homeDirectory}/.colima/default/docker.sock";
      description = ''
        Path to the Colima Docker daemon socket (derived). Single source for
        consumers like claude-code's sandbox allowlist, so the path can't drift.
      '';
    };

    cpu = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Number of CPUs allocated to the Colima VM.";
    };

    memory = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = ''
        Memory allocated to the Colima VM, in GiB. The default of 4 gives
        shared tenants headroom over Colima's
        built-in 2 GiB default, which is prone to VM-wide OOM kills.
      '';
    };

    disk = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = ''
        Disk size for the Colima VM, in GiB. Null leaves it unmanaged.
        Note: Colima can only grow the disk, never shrink it.
      '';
    };

    sshAgent = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Forward the host SSH agent into the Colima VM (colima start --ssh-agent),
        equivalent to forwardAgent in colima.yaml. Lets containers use host SSH keys.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.packages = with pkgs; [
      colima
      docker
      docker-compose
    ];

    home.sessionVariables = {
      COLIMA_HOME = "${config.home.homeDirectory}/.colima";
      DOCKER_HOST = "unix://${cfg.socketPath}";
    };

    launchd.agents.colima = {
      enable = true;
      config = {
        Label = "dev.${user}.colima";
        EnvironmentVariables = {
          COLIMA_HOME = "${config.home.homeDirectory}/.colima";
          PATH = "/etc/profiles/per-user/${user}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        ProgramArguments = [
          "${colimaStartScript}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/colima.out.log";
        StandardErrorPath = "/tmp/colima.err.log";
      };
    };
  };
}
