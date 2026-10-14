# overlays/kubernetes-helm-skip-tests.nix
#
# TEMPORARY workaround for a nixpkgs build failure.
#
# kubernetes-helm's checkPhase has failed to build in this nixpkgs line, so its
# tests are disabled.
#
# REMOVE this overlay (and its entry in ./default.nix) once
# `nix build nixpkgs#kubernetes-helm` succeeds again without it.
final: prev: {
  kubernetes-helm = prev.kubernetes-helm.overrideAttrs (_: {
    doCheck = false;
  });
}
