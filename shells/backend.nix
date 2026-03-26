{ pkgs }:
pkgs.devshell.mkShell {
  name = "backend";

  commands = [
    # php
    {
      package = pkgs.php83;
      category = "php";
    }
    {
      package = pkgs.php83Packages.composer;
      category = "php";
    }

    # database
    {
      package = pkgs.mysql80;
      category = "database";
    }

    # containers
    {
      package = pkgs.docker-client;
      category = "containers";
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
    {
      package = pkgs.jq;
      category = "tools";
    }
    {
      package = pkgs.yq-go;
      category = "tools";
    }
    {
      package = pkgs.curl;
      category = "tools";
    }
    {
      package = pkgs.ripgrep;
      category = "tools";
    }
  ];
}
