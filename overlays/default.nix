# overlays/default.nix
# Every overlay applied to nixpkgs, on both hosts.
{ inputs }:
[
  inputs.nix-vscode-extensions.overlays.default
  # TEMPORARY: fix lima/colima build on aarch64-darwin (cctools ld64
  # SIGTRAP). Remove once nixpkgs includes nixpkgs#541023. See the file.
  (import ./lima-darwin-lld.nix)
  # TEMPORARY: skip debugpy's failing test_lldb_command on aarch64-darwin,
  # which blocks ms-python.python. Remove once fixed upstream. See the file.
  (import ./debugpy-darwin-lldb-test.nix)
]
