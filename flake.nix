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

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      devshell,
      ...
    }:
    let
      # Target systems
      linuxSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin";
      nixpkgsConfig = { allowUnfree = true; };
      # Import pkgs for Linux (outside Home Manager config to avoid warning with useGlobalPkgs)
      pkgs = import nixpkgs {
        system = linuxSystem;
        config = nixpkgsConfig;
      };
      forEachSystem =
        f:
        builtins.listToAttrs (
          map
            (system: {
              name = system;
              value = f (import nixpkgs {
                inherit system;
                config = nixpkgsConfig;
                overlays = [ devshell.overlays.default ];
              });
            })
            [
              linuxSystem
              darwinSystem
            ]
        );
    in
    {
      devShells = forEachSystem (pkgs: {
        default = import ./shells/default.nix { inherit pkgs; };
        frontend = import ./shells/frontend.nix { inherit pkgs; };
        backend = import ./shells/backend.nix { inherit pkgs; };
        devops = import ./shells/devops.nix { inherit pkgs; };
      });

      homeConfigurations."jonas" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./home.nix
          ./modules/shared.nix
          ./hosts/popos.nix
        ];
      };

      darwinConfigurations."jonas-mac" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";

        modules = [
          ./hosts/darwin
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          (
            { lib, ... }:
            {
              nixpkgs.hostPlatform = "aarch64-darwin";
              nixpkgs.config = nixpkgsConfig;
              nix.settings.experimental-features = [
                "nix-command"
                "flakes"
              ];

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";

              # Hard override to avoid null merges from other modules
              home-manager.users.jonas.home.homeDirectory = lib.mkForce "/Users/jonas";

              home-manager.users.jonas = {
                imports = [
                  ./home.nix
                  ./modules/shared.nix
                ];
              };

            }
          )
        ];
      };
    };
}
