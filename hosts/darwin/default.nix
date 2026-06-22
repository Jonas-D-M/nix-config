# hosts/darwin/default.nix
# The macOS host: flake/Home-Manager wiring, machine identity, and per-host
# toggles. System preferences live in ./system.nix, Homebrew in ./homebrew.nix.
{
  pkgs,
  lib,
  nixpkgsConfig,
  sharedOverlays,
  darwinSystem,
  userName,
  ...
}:
let
  # "jonas" -> "Jonas" for the display-oriented machine names below.
  displayName =
    lib.toUpper (builtins.substring 0 1 userName)
    + builtins.substring 1 (builtins.stringLength userName) userName;
in
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
      inherit userName;
      vscode-marketplace-release = pkgs.vscode-marketplace-release;
    };
    home-manager.users.${userName} = {
      imports = [
        ../../modules/shared.nix
        # colima is macOS-only, so it's imported here rather than in shared.nix
        ../../modules/darwin/colima
      ];
      # mkForce needed: useUserPackages makes nix-darwin common.nix set homeDirectory = null
      home.homeDirectory = lib.mkForce "/Users/${userName}";
      custom.services.colima.enable = true;
      custom.services.colima.sshAgent = true;
      custom.claudeCode.enableDocker = true;
    };

    # nix-darwin owns nix-daemon
    nix.enable = true;
    # set once; keep stable
    system.stateVersion = 6;
    # must match your Mac short username
    system.primaryUser = userName;

    programs.zsh.enable = true;

    networking = {
      computerName = "${displayName}'s MacBook Pro";
      hostName = "${displayName}-MacBook-Pro";
      localHostName = "${userName}-mac";
    };

    # keep system packages empty; you install via Home Manager
    environment.systemPackages = [ ];

    custom.services.linearmouse.enable = true;
  };
}
