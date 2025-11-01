{
  description = "Jonas Home Manager (darwin + linux)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      sops-nix,
      ...
    }:
    let
      # Target systems
      linuxSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin";

      # pkgs per-system
      linuxPkgs = import nixpkgs { system = linuxSystem; };

      # Small helper for Linux HM configs
      mkHome =
        modules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = linuxPkgs;
          extraSpecialArgs = { inherit sops-nix; };
          modules = modules;
        };
    in
    {
      #
      # LINUX HOME-MANAGER CONFIG
      #
      # NOTE: We force home.homeDirectory here so you don't have to change other files.
      #
      homeConfigurations."jonas-home" = mkHome [
        ./home.nix
        ./modules/shared.nix
        ./hosts/popos.nix

        # Inline module to force the home directory on Linux
        (
          { lib, ... }:
          {
            home.username = lib.mkForce "jonas";
            home.homeDirectory = lib.mkForce "/home/jonas";
          }
        )
      ];

      #
      # MACOS (nix-darwin + HM) CONFIG
      #
      darwinConfigurations."jonas-mac" = nix-darwin.lib.darwinSystem {
        system = darwinSystem;

        modules = [
          ./hosts/macos.nix
          home-manager.darwinModules.home-manager
          sops-nix.darwinModules.sops

          {
            nixpkgs.hostPlatform = darwinSystem;

            # Home Manager integration
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # Provide sops-nix to HM modules
            home-manager.extraSpecialArgs = { inherit sops-nix; };

            # User module + imports
            home-manager.users.jonas = {
              imports = [
                ./home.nix
                ./modules/shared.nix
              ];

              # Force the path so null/optional defaults can't win
              home.homeDirectory = nixpkgs.lib.mkForce "/Users/jonas";
            };

            # sops-nix (darwin key location)
            sops.age.keyFile = "/Users/jonas/.config/sops/age/keys.txt";

            # Keep unfree on the darwin side too
            nixpkgs.config.allowUnfree = true;

            # Nix features for darwin
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
          }
        ];
      };
    };
}
