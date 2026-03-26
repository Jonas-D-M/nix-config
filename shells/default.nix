{ pkgs }:
pkgs.devshell.mkShell {
  name = "nix-config";

  commands = [
    # essentials
    {
      package = pkgs.curl;
      category = "essentials";
    }
    {
      package = pkgs.wget;
      category = "essentials";
    }
    {
      package = pkgs.gnupg;
      category = "essentials";
    }
    {
      package = pkgs.jq;
      category = "essentials";
    }
    {
      package = pkgs.yq-go;
      category = "essentials";
    }
    {
      package = pkgs.ripgrep;
      category = "essentials";
    }
    {
      package = pkgs.unzip;
      category = "essentials";
    }
    {
      package = pkgs.zip;
      category = "essentials";
    }

    # dev
    {
      package = pkgs.php83;
      category = "dev";
    }
    {
      package = pkgs.php83Packages.composer;
      category = "dev";
    }
    {
      package = pkgs.bun;
      category = "dev";
    }

    # containers / k8s
    {
      package = pkgs.kubectl;
      category = "k8s";
    }
    {
      package = pkgs.kubernetes-helm;
      category = "k8s";
    }
    {
      package = pkgs.krew;
      category = "k8s";
    }
    {
      package = pkgs.k9s;
      category = "k8s";
    }

    # nix tooling
    {
      package = pkgs.nixfmt;
      category = "nix";
    }
    {
      package = pkgs.sops;
      category = "nix";
    }
    {
      package = pkgs.age;
      category = "nix";
    }
  ];
}
