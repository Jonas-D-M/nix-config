# modules/git-ssh-sign.nix
{ config, lib, ... }:
{
  programs.ssh = {
    enable = true;
    # HM defaults will be removed; explicitly set what you want.
    enableDefaultConfig = false;

    # Safer default: don't forward the agent everywhere.
    matchBlocks = {
      "*" = {
        forwardAgent = false;
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";

        # If you want to force specific identities, uncomment below
        # identityFile = [
        #   "~/.ssh/id_ed25519"
        #   "~/.ssh/id_ed25519_work"
        # ];
        # identitiesOnly = true;

        # OpenSSH option not modeled as a boolean in HM; set via extraOptions.
        extraOptions = {
          AddKeysToAgent = "yes";
        };

        # Forward the agent only for GitHub (replaces the old global forwardAgent).
        forwardAgent = true;
      };
    };
  };

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Jonas De Meyer";
        email = "43569205+Jonas-D-M@users.noreply.github.com";
        signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };

      init.defaultBranch = "master";

      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
      };

      commit.gpgSign = true;
      tag.gpgSign = true;
    };

    includes = [
      {
        condition = "gitdir:${config.home.homeDirectory}/work/**";
        path = "${config.home.homeDirectory}/.gitconfig-work-ssh";
      }
    ];
  };

  # The included work override (identity + signing key)
  home.file.".gitconfig-work-ssh".text = ''
    [user]
      name = Jonas De Meyer
      email = 144120822+Jonas-PRF@users.noreply.github.com
      signingkey = ~/.ssh/id_ed25519_work
    [gpg]
      format = ssh
  '';

  # allowed_signers is now generated in secrets.nix ensurePubKeys activation step.
}
