# hosts/darwin/default.nix
# The macOS host: flake/Home-Manager wiring, machine identity, and per-host
# toggles. System preferences live in ./system.nix, Homebrew in ./homebrew.nix.
{
  pkgs,
  lib,
  nixpkgsConfig,
  sharedOverlays,
  darwinSystem,
  ...
}:
{
  imports = [
    ./system.nix
    ./homebrew.nix
    ../../modules/darwin/linearmouse
  ];

  config = {
    # nixpkgs + nix flake wiring (values passed from flake.nix via specialArgs)
    nixpkgs.hostPlatform = darwinSystem;
    nixpkgs.config = nixpkgsConfig;
    nixpkgs.overlays = sharedOverlays;
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Home Manager runs inside nix-darwin (it owns the outer evaluation).
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "hm-backup";
    home-manager.extraSpecialArgs = {
      vscode-marketplace-release = pkgs.vscode-marketplace-release;
    };
    home-manager.users.jonas = {
      imports = [ ../../modules/shared.nix ];
      # mkForce needed: useUserPackages makes nix-darwin common.nix set homeDirectory = null
      home.homeDirectory = lib.mkForce "/Users/jonas";
      custom.services.colima.enable = true;
      custom.services.colima.sshAgent = true;
      custom.claudeCode.enableDocker = true;
    };

    # nix-darwin owns nix-daemon
    nix.enable = true;
    # set once; keep stable
    system.stateVersion = 6;
    # must match your Mac short username
    system.primaryUser = "jonas";

    programs.zsh.enable = true;

    networking = {
      computerName = "Jonas's MacBook Pro";
      hostName = "Jonas-MacBook-Pro";
      localHostName = "jonas-mac";
    };

    # keep system packages empty; you install via Home Manager
    environment.systemPackages = [ ];

    custom.services.linearmouse.enable = true;
  };
}
