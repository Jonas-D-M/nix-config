# modules/ssh/keys.nix
# The SSH key registry: the single declarative list of every managed key.
# Key generation, .pub, allowed_signers, git commit-signing (../git), and the
# work-context dir all derive fully from this list. SSH host routing
# (config.nix) reads key names + the work context from here, but the per-host
# blocks (github.com, ssh.dev.azure.com) and their ssh options are templated
# there — a key for a brand-new host also needs a routing block added there.
{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.ssh;
  homeDir = config.home.homeDirectory;
  user = config.home.username;

  # "~/work" → "/Users/jonas/work". Already-absolute paths are left untouched
  # so they are not doubled onto homeDir.
  expandDir = d: if lib.hasPrefix "~" d then homeDir + lib.removePrefix "~" d else d;

  resolvedWorkKey = lib.findFirst (
    k: k.onlyInDir != null
  ) (throw "custom.ssh: registry has no work-context key (a key with onlyInDir set)") cfg.keys;
in
{
  options.custom.ssh = {
    keys = lib.mkOption {
      internal = true;
      description = "The SSH key registry: every managed key and its role.";
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              # Interpolated into shell (activation) and ssh config; constrain to
              # a safe filename charset so a stray quote/glob cannot break either.
              type = lib.types.strMatching "[A-Za-z0-9_.-]+";
              description = "Filename under ~/.ssh.";
            };
            type = lib.mkOption {
              type = lib.types.enum [
                "ed25519"
                "rsa"
              ];
              default = "ed25519";
              description = "Key type; rsa implies -b 4096.";
            };
            comment = lib.mkOption {
              type = lib.types.str;
              description = "ssh-keygen comment (-C).";
            };
            signs = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "allowed_signers principal, or null when the key does not sign commits.";
            };
            serves = lib.mkOption {
              type = lib.types.str;
              description = "SSH host this key authenticates to.";
            };
            onlyInDir = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Work context: the dir under which this key/identity activates (null = unconditional). Drives both SSH key selection and git signing identity.";
            };
          };
        }
      );
      default = [
        {
          name = "id_ed25519";
          comment = "${user}.personal";
          signs = "${user}.personal";
          serves = "github.com";
        }
        {
          name = "id_ed25519_work";
          comment = "${user}.work";
          signs = "${user}.work";
          serves = "github.com";
          onlyInDir = "~/work";
        }
        {
          name = "id_rsa_azure_devops";
          type = "rsa";
          comment = "${user}.work.azure_devops";
          serves = "ssh.dev.azure.com";
        }
      ];
    };

    # Derived, read-only views so keygen/config/git consume the SAME facts
    # instead of each re-deriving them (which let routing and signing drift).
    signers = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.listOf lib.types.raw;
      default = lib.filter (k: k.signs != null) cfg.keys;
      description = "Registry keys that sign git commits (derived).";
    };
    workKey = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.raw;
      default = resolvedWorkKey;
      description = "The single work-context key — the one with onlyInDir set (derived).";
    };
    workDir = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.str;
      default = expandDir resolvedWorkKey.onlyInDir;
      description = "Absolute work-context dir, expanded from the work key's onlyInDir (derived).";
    };
  };
}
