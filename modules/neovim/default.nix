{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    neovim
    fd
    tree-sitter
    gcc
    lua-language-server
    stylua
  ];

  # Sole owner of $EDITOR across the config.
  home.sessionVariables.EDITOR = "nvim";

  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
  };

  # Live symlink so config edits don't need a rebuild.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/modules/neovim/config";
}
