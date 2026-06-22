# hosts/darwin/homebrew.nix
# Homebrew: the casks/brews/taps installed via the nix-darwin homebrew module.
{
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.custom.darwin.homebrew;
in
{
  options.custom.darwin.homebrew = {
    microsoft-office.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install Microsoft Office bloat via Homebrew casks.";
    };
  };

  config = {
    # nix-homebrew installs and owns the Homebrew prefix declaratively, so a
    # fresh Mac needs no manual `brew` install. autoMigrate adopts an existing
    # /opt/homebrew on the first switch instead of failing.
    nix-homebrew = {
      enable = true;
      user = userName;
      autoMigrate = true;
    };

    homebrew = {
      enable = true;
      taps = [ "supabase/tap" ];
      brews = [ "supabase" ];
      casks = [
        "wezterm"
        "visual-studio-code"
        "spotify"
        "google-chrome"
        "dbeaver-community"
        "postman"
        "microsoft-teams"
        "clockify"
        "slack"
        "microsoft-outlook"
        "font-jetbrains-mono-nerd-font"
        "figma"
        "windows-app"
        "obsidian"
        "chatgpt"
        "claude"
        "bitwarden"
        "copilot-cli"
        "codex-app"
      ]
      ++ lib.optionals cfg.microsoft-office.enable [
        "microsoft-excel"
        "microsoft-word"
        "microsoft-powerpoint"
      ];
      onActivation.cleanup = "zap";
    };
  };
}
