# overlays/lima-darwin-lld.nix
#
# TEMPORARY workaround for a nixpkgs regression on aarch64-darwin.
#
# The nixpkgs-built cctools ld64 (1010.6) crashes with SIGTRAP (Trace/BPT
# trap: 5 -> clang exit 133) when linking limactl, whose cgo link line
# repeats -framework Foundation/Virtualization many times. This breaks
# lima/lima-full and therefore colima.
#
# Upstream fix (link with ld64.lld instead of cctools ld) is merged in
# nixpkgs PR #541023 (2026-07-13); the underlying toolchain fix is
# PR #536365 ("ld64: disable hardening again"). Our pinned nixpkgs predates
# these. This overlay replicates PR #541023 locally.
#
# REMOVE this overlay (and its entry in flake.nix's sharedOverlays) once
# nixpkgs advances past commit 605e1b1ee4bfde64892f34f002852453a1038c20.
#
# lima-full = lima.override { withAdditionalGuestAgents = true; }, and .override
# discards a prior overrideAttrs, so the fix must be applied to both attrs.
final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin (
  let
    useLld =
      pkg:
      pkg.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages.lld ];
        env = (old.env or { }) // {
          NIX_CFLAGS_LINK = "-fuse-ld=${final.lib.getExe' final.llvmPackages.lld "ld64.lld"}";
        };
      });
  in
  {
    lima = useLld prev.lima;
    lima-full = useLld prev.lima-full;
  }
)
