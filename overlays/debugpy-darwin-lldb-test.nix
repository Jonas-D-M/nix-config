# overlays/debugpy-darwin-lldb-test.nix
#
# TEMPORARY workaround for a nixpkgs regression on aarch64-darwin.
#
# debugpy 1.8.22's test_lldb_command fails (`assert False`) on Darwin, where
# nixpkgs patches the attach path to a hardcoded lldb (hardcode-lldb.patch).
# 965 other tests pass. debugpy is pulled in by the ms-python.python VS Code
# extension, so this one test blocks the whole system build.
#
# REMOVE this overlay (and its entry in ./default.nix) once
# nixpkgs' debugpy builds again on aarch64-darwin without it.
final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyFinal: pyPrev: {
      debugpy = pyPrev.debugpy.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [ "test_lldb_command" ];
      });
    })
  ];
}
