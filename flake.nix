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

    nix-shells = {
      url = "github:Jonas-D-M/nix-shells";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
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
      nix-shells,
      nix-vscode-extensions,
      ...
    }:
    let
      # Target systems
      linuxSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin";
      nixpkgsConfig = { allowUnfree = true; };
      # Import pkgs for Linux with vscode-extensions overlay so allowUnfree applies
      pkgs = import nixpkgs {
        system = linuxSystem;
        config = nixpkgsConfig;
        overlays = [ nix-vscode-extensions.overlays.default ];
      };
    in
    {
      inherit (nix-shells) devShells;

      homeConfigurations."jonas" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          vscode-marketplace-release = pkgs.vscode-marketplace-release;
        };

        modules = [
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
            { lib, pkgs, ... }:
            {
              nixpkgs.hostPlatform = "aarch64-darwin";
              nixpkgs.config = nixpkgsConfig;
              nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
              nix.settings.experimental-features = [
                "nix-command"
                "flakes"
              ];

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";
              home-manager.extraSpecialArgs = {
                vscode-marketplace = pkgs.vscode-marketplace;
                vscode-marketplace-release = pkgs.vscode-marketplace-release;
              };

              # mkForce needed: useUserPackages causes nix-darwin common.nix to set homeDirectory = null
              home-manager.users.jonas.home.homeDirectory = lib.mkForce "/Users/jonas";

              home-manager.users.jonas = {
                imports = [
                  ./modules/shared.nix
                ];
                custom.services.colima.enable = true;
              };

            }
          )
        ];
      };
    };
}
