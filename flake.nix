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

  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      ...
    }:
    let
      # Target systems
      linuxSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin";
      # Import pkgs for Linux with unfree enabled (outside Home Manager config to avoid warning with useGlobalPkgs)
      pkgs = import nixpkgs {
        system = linuxSystem;
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations."jonas" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./home.nix
          ./modules/shared.nix
        ];
      };

      darwinConfigurations."jonas-mac" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";

        modules = [
          ./hosts/darwin
          ./modules/darwin/aerospace
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          (
            { lib, ... }:
            {
              nixpkgs.hostPlatform = "aarch64-darwin";
              nix.settings.experimental-features = [
                "nix-command"
                "flakes"
              ];

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

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
