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
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      nix-shells,
      ...
    }:
    let
      # Target systems
      linuxSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin";
      # Single source for the username; threaded into both configs.
      userName = "jonas";
      # nixpkgs settings for both hosts: Linux instantiates pkgs from them here,
      # nix-darwin receives them as nixpkgs.* options below.
      nixpkgsArgs = {
        config.allowUnfree = true;
        overlays = import ./overlays { inherit inputs; };
      };
      pkgs = import nixpkgs (nixpkgsArgs // { system = linuxSystem; });
    in
    {
      inherit (nix-shells) devShells;

      homeConfigurations.${userName} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = { inherit userName; };

        modules = [
          ./modules/home
          ./hosts/popos
        ];
      };

      darwinConfigurations."${userName}-mac" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit userName; };

        modules = [
          {
            nixpkgs = nixpkgsArgs // {
              hostPlatform = darwinSystem;
            };
          }
          ./hosts/darwin
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
        ];
      };
    };
}
