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
      taps = [
        "supabase/tap"
        {
          # Homebrew 6.0 enables HOMEBREW_REQUIRE_TAP_TRUST by default, which
          # refuses to load formulae from non-official taps during activation.
          # Trusting the tap lets its formulae (krr) install without prompting.
          name = "robusta-dev/homebrew-krr";
          trusted = true;
        }
      ];
      brews = [
        "supabase"
        "krr"
      ];
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
      # On every `drb`: refresh definitions (autoUpdate), upgrade outdated
      # casks/brews (upgrade), and remove anything no longer listed (cleanup).
      # Casks marked auto_updates / version :latest are skipped by brew upgrade,
      # so this won't fight apps that update themselves.
      onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "zap";
      };
    };
  };
}
