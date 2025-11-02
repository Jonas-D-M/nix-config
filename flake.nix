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

    nixgl.url = "github:nix-community/nixGL";

  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nixgl,
      ...
    }:
    let
      # Target systems
      linuxSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${linuxSystem};
    in
    {
       homeConfigurations."jonas" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./home.nix
          ./modules/shared.nix
        ];
      };

      #
      # MACOS (nix-darwin + HM) CONFIG
      #
      darwinConfigurations."jonas-mac" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/macos.nix
          home-manager.darwinModules.home-manager
          {
            nixpkgs.hostPlatform = "aarch64-darwin";

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.jonas = {
              imports = [
                ./home.nix
                ./modules/shared.nix
              ];
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
