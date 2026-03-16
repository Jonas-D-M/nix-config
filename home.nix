{ config, pkgs, ... }:
{
  home.username = "jonas";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/jonas" else "/home/jonas";
  news.display = "silent";
}
