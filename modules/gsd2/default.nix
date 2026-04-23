# modules/gsd2/default.nix
# Installs gsd-2 (https://github.com/gsd-build/gsd-2) via its published npm
# package `gsd-pi`. The package ships native deps (sharp, playwright) and a
# postinstall script, so we install it globally with pnpm in an activation
# script rather than building it through Nix. The version gate keeps this
# idempotent — subsequent `drb`/`hms` runs only touch the install when the
# pinned version changes.
{
  pkgs,
  config,
  lib,
  ...
}:
let
  version = "2.77.0";
  pnpmHome = "${config.home.homeDirectory}/.local/share/pnpm";
in
{
  home.activation.installGsd2 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    export PNPM_HOME="${pnpmHome}"
    export PATH="$PNPM_HOME:${pkgs.nodejs}/bin:$PATH"
    mkdir -p "$PNPM_HOME"

    current=""
    if "${pkgs.pnpm}/bin/pnpm" list -g gsd-pi 2>/dev/null \
        | ${pkgs.gnugrep}/bin/grep -Eo 'gsd-pi[[:space:]]+[0-9][^[:space:]]*' \
        | ${pkgs.gnugrep}/bin/grep -Eo '[0-9][^[:space:]]*$' \
        > /tmp/.gsd-pi-version 2>/dev/null; then
      current="$(cat /tmp/.gsd-pi-version)"
    fi
    rm -f /tmp/.gsd-pi-version

    if [ "$current" != "${version}" ]; then
      echo "Installing gsd-pi@${version} via pnpm (was: \"$current\")..."
      "${pkgs.pnpm}/bin/pnpm" add -g "gsd-pi@${version}"
    fi
  '';
}
