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

    # linting / formatting
    {
      package = pkgs.prettierd;
      category = "linting / formatting";
    }
    {
      package = pkgs.eslint_d;
      category = "linting / formatting";
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
      package = pkgs.curl;
      category = "tools";
    }
    {
      package = pkgs.ripgrep;
      category = "tools";
    }
  ];
}
