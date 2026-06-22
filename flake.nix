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
      # Single source for the username; threaded into both configs.
      userName = "jonas";
      nixpkgsConfig = {
        allowUnfree = true;
      };
      sharedOverlays = [
        nix-vscode-extensions.overlays.default
      ];
      # Import pkgs for Linux with vscode-extensions overlay so allowUnfree applies
      pkgs = import nixpkgs {
        system = linuxSystem;
        config = nixpkgsConfig;
        overlays = sharedOverlays;
      };
    in
    {
      inherit (nix-shells) devShells;

      homeConfigurations.${userName} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          inherit userName;
          vscode-marketplace-release = pkgs.vscode-marketplace-release;
        };

        modules = [
          ./modules/shared.nix
          ./hosts/popos.nix
        ];
      };

      darwinConfigurations."${userName}-mac" = nix-darwin.lib.darwinSystem {
        system = darwinSystem;

        specialArgs = {
          inherit
            nixpkgsConfig
            sharedOverlays
            darwinSystem
            userName
            ;
        };

        modules = [
          ./hosts/darwin
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
        ];
      };
    };
}
