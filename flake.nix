{
  description = "Jonas Home Manager";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
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
      # Linux
      linuxSystem = "x86_64-linux";
      linuxPkgs = import nixpkgs { system = linuxSystem; };

      mkHome =
        modules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = linuxPkgs;
          extraSpecialArgs = { inherit sops-nix; };
          modules = modules;
        };

      # macOS
      darwinSystem = "aarch64-darwin";
    in
    {
      homeConfigurations."jonas-home" = mkHome [
        ./home.nix
        ./modules/shared.nix
        ./hosts/popos.nix
      ];
      darwinConfigurations."jonas-mac" = nix-darwin.lib.darwinSystem {
        system = darwinSystem;

        modules = [
          # Your host-specific darwin config
          ./hosts/macos.nix

          # Home Manager as a nix-darwin module
          home-manager.darwinModules.home-manager

          # sops-nix for darwin
          sops-nix.darwinModules.sops

          # Plumbing to hook your existing Home Manager config for user "jonas"
          {
            # Make sure darwin knows the platform and where your home is
            nixpkgs.hostPlatform = darwinSystem;

            # Home Manager options
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # Reuse your existing HM config on macOS
            home-manager.users."jonas" = import ./home.nix;

            # sops-nix minimal defaults (adapt to your secrets workflow)
            sops = {
              defaultSopsFile = ./secrets/secrets.yaml; # optional
              age.keyFile = "/Users/jonas/.config/sops/age/keys.txt"; # optional
            };
          }
        ];
      };
    }
}