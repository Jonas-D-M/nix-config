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
        system = "aarch64-darwin";
        modules = [
          ./hosts/macos.nix
          home-manager.darwinModules.home-manager
          sops-nix.darwinModules.sops
          {
            nixpkgs.hostPlatform = "aarch64-darwin";

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit sops-nix; };

            # IMPORTANT: attr key and values match your mac user
            home-manager.users.jonasdemeyer = {
              imports = [
                ./home.nix
                ./modules/shared.nix
              ];
              home.username = nixpkgs.lib.mkForce "jonasdemeyer";
              home.homeDirectory = nixpkgs.lib.mkForce "/Users/jonasdemeyer";
            };

            nixpkgs.config.allowUnfree = true;
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
          }
        ];
      };

    };
}
