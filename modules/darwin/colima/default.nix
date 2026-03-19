{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.colima;
  user = config.system.primaryUser;
in
{
  options.services.colima = {
    enable = lib.mkEnableOption "Colima (Docker runtime via Lima VM + auto-start)";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {
      custom.extraHomePackages = with pkgs; [
        colima
        docker
        docker-compose
      ];

      home.sessionVariables = {
        DOCKER_HOST = "unix:///Users/${user}/.colima/default/docker.sock";
      };

      launchd.agents.colima = {
        enable = true;
        config = {
          Label = "dev.${user}.colima";
          EnvironmentVariables = {
            PATH = "/etc/profiles/per-user/${user}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          ProgramArguments = [
            "${pkgs.colima}/bin/colima"
            "start"
            "--foreground"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/colima.out.log";
          StandardErrorPath = "/tmp/colima.err.log";
        };
      };
    };
  };
}
