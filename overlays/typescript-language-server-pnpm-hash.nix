# overlays/typescript-language-server-pnpm-hash.nix
#
# TEMPORARY workaround for a wrong hash in nixpkgs.
#
# typescript-language-server 6.0.2 pins a pnpmDeps hash that doesn't match
# what the fetcher produces, so it fails with a hash mismatch on every
# platform (Hydra has no build of it either). It's installed by the
# claude-code module for the typescript-lsp plugin, so it blocks the build.
# This re-fetches the deps exactly as nixpkgs does, with the correct hash.
#
# Only applies to 6.0.2: on any other version this overlay does nothing.
# REMOVE this overlay (and its entry in ./default.nix) once nixpkgs ships a
# typescript-language-server that builds without it.
final: prev: {
  # The version check sits inside the attribute: the overlay's attribute names
  # must not depend on package values, or nixpkgs hits infinite recursion.
  typescript-language-server =
    if prev.typescript-language-server.version != "6.0.2" then
      prev.typescript-language-server
    else
      prev.typescript-language-server.overrideAttrs (
        finalAttrs: old: {
          pnpmDeps = final.fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            pnpm = final.pnpm_12;
            fetcherVersion = 4;
            hash = "sha256-PmyJb8090pEPc09Tbv8RgdvQpzpba2L8ve87+aVncQU=";
          };
        }
      );
}
