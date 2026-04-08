# modules/colima/default.nix
# Darwin-only: Colima Docker runtime + launchd auto-start
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.services.colima;
  user = config.home.username;
  colimaStartScript = pkgs.writeShellScript "colima-start" ''
    # Clean up stale VM state from unclean shutdown before starting
    ${pkgs.colima}/bin/colima stop --force 2>/dev/null || true
    exec ${pkgs.colima}/bin/colima start --foreground
  '';
in
{
  options.custom.services.colima = {
    enable = lib.mkEnableOption "Colima (Docker runtime via Lima VM + auto-start)";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.packages = with pkgs; [
      colima
      docker
      docker-compose
    ];

    home.sessionVariables = {
      COLIMA_HOME = "${config.home.homeDirectory}/.colima";
      DOCKER_HOST = "unix://${config.home.homeDirectory}/.colima/default/docker.sock";
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
