{
  description = "Jonas Home Manager";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      sops-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      mkHome =
        modules:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          # pass sops-nix to your modules (secrets.nix imports it)
          extraSpecialArgs = { inherit sops-nix; };
          modules = modules;
        };
    in
    {
      homeConfigurations."jonas-home" = mkHome [
        ./home.nix
        ./modules/shared.nix
        ./hosts/popos.nix
      ];
    };
}
