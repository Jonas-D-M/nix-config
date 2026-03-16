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

      pull.ff = "only";

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
        condition = "gitdir:${config.home.homeDirectory}/work/**";
        contents = {
          user = {
            name = "Jonas De Meyer";
            email = "144120822+Jonas-PRF@users.noreply.github.com";
            signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519_work";
          };
          core.sshCommand = "ssh -o IdentitiesOnly=yes -i ${config.home.homeDirectory}/.ssh/id_ed25519_work";
          gpg.format = "ssh";
        };
      }
    ];
  };
}
