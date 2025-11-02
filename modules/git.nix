{ config, lib, ... }:
{
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

}
