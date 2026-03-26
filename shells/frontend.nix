{ pkgs }:
pkgs.devshell.mkShell {
  name = "frontend";

  commands = [
    # runtime
    {
      package = pkgs.nodejs_22;
      category = "runtime";
    }
    {
      package = pkgs.bun;
      category = "runtime";
    }

    # package managers
    {
      package = pkgs.pnpm;
      category = "package managers";
    }

    # tools
    {
      package = pkgs.jq;
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
