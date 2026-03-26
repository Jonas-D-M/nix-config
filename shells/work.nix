{ pkgs }:
pkgs.devshell.mkShell {
  name = "work";

  commands = [
    # backend
    {
      package = pkgs.php83;
      category = "backend";
    }
    {
      package = pkgs.php83Packages.composer;
      category = "backend";
    }
    {
      package = pkgs.mysql80;
      category = "backend";
    }

    # frontend
    {
      package = pkgs.nodejs_22;
      category = "frontend";
    }
    {
      package = pkgs.pnpm;
      category = "frontend";
    }
    {
      package = pkgs.bun;
      category = "frontend";
    }

    # utilities
    {
      package = pkgs.jq;
      category = "utilities";
    }
    {
      package = pkgs.ripgrep;
      category = "utilities";
    }
    {
      package = pkgs.curl;
      category = "utilities";
    }
  ];
}
