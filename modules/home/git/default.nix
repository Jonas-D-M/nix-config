# modules/home/git/default.nix
# Git with SSH commit/tag signing. The personal identity is the default; any
# repo under the work context (~/work) switches to the work identity via a
# gitdir: include, which also pins core.sshCommand to the work key. Keys and
# the work dir come from the SSH key registry (../ssh/keys.nix). pull.ff = only.
{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.ssh;
  homeDir = config.home.homeDirectory;

  defaultSigner = lib.findFirst (
    k: k.onlyInDir == null
  ) (throw "git: no default signing key in registry") cfg.signers;

  # Resolved once in keys.nix and shared with ../ssh so signing and routing
  # cannot disagree on the work key or the work-context dir.
  workSigner = cfg.workKey;
  workDir = cfg.workDir;
in
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Jonas De Meyer";
        email = "43569205+Jonas-D-M@users.noreply.github.com"; # personal
        signingKey = "${homeDir}/.ssh/${defaultSigner.name}"; # personal signing (SSH)
      };

      init.defaultBranch = "master";

      pull.ff = "only";

      push.autoSetupRemote = true;

      # SSH commit signing (global)
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = "${homeDir}/.ssh/allowed_signers";
      };

      commit.gpgSign = true;
      tag.gpgSign = true;
    };

    includes = [
      {
        condition = "gitdir:${workDir}/**";
        contents = {
          user = {
            name = "Jonas De Meyer";
            email = "144120822+Jonas-PRF@users.noreply.github.com";
            signingKey = "${homeDir}/.ssh/${workSigner.name}";
          };
          core.sshCommand = "ssh -o IdentitiesOnly=yes -i ${homeDir}/.ssh/${workSigner.name}";
          gpg.format = "ssh";
        };
      }
    ];
  };

  # ~/work is the work-context root that the gitdir include above and the ssh
  # work key both key off — ensure it exists. workDir is the same registry-
  # derived path, so this follows if the work context ever moves.
  home.activation.createWorkDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "${workDir}" ]; then
      echo "Creating ${workDir} directory..."
      mkdir -p "${workDir}"
    fi
  '';
}
