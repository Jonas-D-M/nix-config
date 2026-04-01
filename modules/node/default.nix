# modules/node/default.nix
# Node.js tooling: fnm, pnpm, and default .nvmrc
{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    fnm
    pnpm
  ];

  home.sessionVariables = {
    PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/share/pnpm"
  ];

  home.file.".nvmrc" = {
    text = "20\n";
  };
}
