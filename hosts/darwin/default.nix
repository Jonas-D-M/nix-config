# hosts/darwin/default.nix
# The macOS host: flake/Home-Manager wiring, machine identity, and per-host
# toggles. System preferences live in ./system.nix, Homebrew in ./homebrew.nix.
{
  lib,
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
    ../../modules/darwin/linearmouse.nix
  ];

  config = {
    # nixpkgs.* (platform, allowUnfree, overlays) is set in flake.nix.
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Weekly GC of anything older than 30 days (system and user generations,
    # i.e. rollback points), plus store deduplication. `nix-cleanup` still
    # runs the same GC by hand.
    nix.gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 3;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
    nix.optimise.automatic = true;

    # Home Manager runs inside nix-darwin (it owns the outer evaluation).
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "hm-backup";
    home-manager.extraSpecialArgs = { inherit userName; };
    home-manager.users.${userName} = {
      imports = [
        ../../modules/home
        # colima and linearmouse are macOS-only HM modules, imported here
        # rather than in modules/home.
        ../../modules/home/colima
        ../../modules/home/linearmouse
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
