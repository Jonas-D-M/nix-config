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
    text = "22\n";
  };

  # User-level npm auth for the GitHub Packages registry (@PRF-FSDT scope).
  # pnpm v11 refuses to expand env vars in repository-controlled .npmrc files,
  # so the token must live in the trusted home .npmrc. GH_TOKEN comes from the
  # shell environment and is expanded by pnpm at install time.
  home.file.".npmrc" = {
    text = ''
      //npm.pkg.github.com/:_authToken=''${GH_TOKEN}
    '';
  };
}
