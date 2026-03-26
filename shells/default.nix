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
      package = pkgs.nodejs_22;
      category = "dev";
    }
    {
      package = pkgs.pnpm;
      category = "dev";
    }
    {
      package = pkgs.bun;
      category = "dev";
    }

    # linting / formatting
    {
      package = pkgs.prettierd;
      category = "linting / formatting";
    }
    {
      package = pkgs.eslint_d;
      category = "linting / formatting";
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
    {
      package = pkgs.kubeswitch;
      category = "k8s";
    }
    {
      package = pkgs.docker-client;
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

    # tools
    {
      package = pkgs.gh;
      category = "tools";
    }
    {
      package = pkgs.direnv;
      category = "tools";
    }
  ];
}
