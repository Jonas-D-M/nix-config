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

    # Pinned nixpkgs for claude-code 2.1.114 — remove once nixos-unstable catches up
    nixpkgs-claude-code.url = "github:nixos/nixpkgs/b12141ef619e0a9c1c84dc8c684040326f27cdcc";

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
      nixpkgs-claude-code,
      ...
    }:
    let
      # Target systems
      linuxSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin";
      nixpkgsConfig = {
        allowUnfree = true;
      };
      # Pin claude-code to 2.1.114 — remove once nixos-unstable catches up
      claudeCodeOverlay = final: prev: {
        claude-code =
          (import nixpkgs-claude-code {
            inherit (prev) system;
            config = nixpkgsConfig;
          }).claude-code-bin;
      };
      sharedOverlays = [
        nix-vscode-extensions.overlays.default
        claudeCodeOverlay
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
        system = darwinSystem;

        modules = [
          ./hosts/darwin
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          (
            { lib, pkgs, ... }:
            {
              nixpkgs.hostPlatform = darwinSystem;
              nixpkgs.config = nixpkgsConfig;
              nixpkgs.overlays = sharedOverlays;
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
                custom.claudeCode.enableDocker = true;
              };

            }
          )
        ];
      };
    };
}
