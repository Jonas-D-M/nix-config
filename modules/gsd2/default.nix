# modules/gsd2/default.nix
# Install the official gsd-pi npm package per
# https://github.com/gsd-build/gsd-2/blob/main/docs/user-docs/getting-started.md
# It ships native deps (sharp, playwright) and a postinstall script, so we
# install it with npm at activation time rather than as a Nix derivation.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  version = "2.77.0";
  npmPrefix = "${config.home.homeDirectory}/.local/share/npm";
in
{
  home.sessionVariables.NPM_CONFIG_PREFIX = npmPrefix;
  home.sessionPath = [ "${npmPrefix}/bin" ];

  home.activation.installGsd2 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    export NPM_CONFIG_PREFIX="${npmPrefix}"
    export PATH="${
      lib.makeBinPath [
        pkgs.nodejs
        pkgs.jq
      ]
    }:$PATH"
    mkdir -p "$NPM_CONFIG_PREFIX"

    pkg="$NPM_CONFIG_PREFIX/lib/node_modules/gsd-pi/package.json"
    current=""
    if [ -f "$pkg" ]; then
      current="$(jq -r .version "$pkg")"
    fi

    if [ "$current" != "${version}" ]; then
      echo "Installing gsd-pi@${version} via npm (was: \"$current\")..."
      npm install -g "gsd-pi@${version}"
    fi
  '';
}
