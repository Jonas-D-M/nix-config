{ config, ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Jonas De Meyer";
        email = "43569205+Jonas-D-M@users.noreply.github.com"; # personal
        signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519"; # personal signing (SSH)
      };

      init.defaultBranch = "master";

      pull.ff = true;

      # SSH commit signing (global)
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
      };

      commit.gpgSign = true;
      tag.gpgSign = true;
    };

    includes = [
      {
        # Match any repo whose working tree is under ~/work/** (Git >= 2.36).
        # If your Git is older, switch to: "gitdir/i:${config.home.homeDirectory}/work/**"
        condition = "gitdir:${config.home.homeDirectory}/work/**";
        path = "${config.home.homeDirectory}/.gitconfig-work-ssh";
      }
    ];
  };

  # Per-work-folder overrides: identity, signing key, and transport key
  home.file.".gitconfig-work-ssh".text = ''
    [user]
      name = Jonas De Meyer
      email = 144120822+Jonas-PRF@users.noreply.github.com
      signingKey = ${config.home.homeDirectory}/.ssh/id_ed25519_work

    [core]
      # Force the work SSH key for pushes/fetches while keeping git@github.com.
      # IdentitiesOnly avoids agent offering other keys.
      sshCommand = ssh -o IdentitiesOnly=yes -i ${config.home.homeDirectory}/.ssh/id_ed25519_work

    # (optional, redundant with global, but harmless to be explicit)
    [gpg]
      format = ssh
  '';
}
