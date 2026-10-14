# modules/home/default.nix
# Home Manager entry point for every host: user identity and the feature
# modules shared by all platforms. Imported directly on Linux and under
# home-manager.users.<name> on macOS, so define ONLY user-level options here.
# Platform-only HM modules (./colima, ./linearmouse) are imported by their host.
{
  pkgs,
  config,
  userName,
  ...
}:
{
  imports = [
    ./packages.nix
    ./claude-code
    ./direnv
    ./gh
    ./git
    ./k9s
    ./kubeswitch
    ./node
    ./openfortivpn
    ./ssh
    ./vscode
    ./wezterm
    ./zsh
  ];

  config = {
    xdg.enable = true;

    # User identity (username is a flake-level constant; see flake.nix)
    home.username = userName;
    home.homeDirectory =
      if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${userName}" else "/home/${userName}";
    news.display = "silent";

    # User-level config only
    home.stateVersion = "25.05";
    home.sessionVariables = {
      KUBECONFIG = "${config.home.homeDirectory}/.config/kube/config";
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    };
    programs.home-manager.enable = true;

    programs.openfortivpn = {
      enable = true;
      vpns = {
        secondary = { };
      };
    };
  };
}
