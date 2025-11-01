{
  description = "Jonas Home Manager";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      mkHome = { system, username, homeDir, modules }:
      let pkgs = import nixpkgs { inherit system; };
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit username homeDir; isDarwin = pkgs.stdenv.isDarwin; };
        modules = modules;
      };
    in
    {
      homeConfigurations."jonas-home" = home-manager.lib.homeManagerConfiguration {
        popos = mkHome {
          system = "x86_64-linux";
          username = "jonas";
          homeDir = "/home/jonas";
          modules = [ 
            ./modules/shared.nix
            ./modules/popos.nix
            ./hosts/popos.nix
           ];
        };
      };
    };
}
