# modules/git-ssh-sign.nix
{ config, ... }:
{
  programs.ssh = {
    enable = true;
    forwardAgent = true; # safe for trusted hosts; set per-host otherwise
    extraConfig = ''
      Host github.com
        HostName github.com
        User git
        AddKeysToAgent yes
        # Uncomment if you want to force specific identities:
        # IdentityFile ~/.ssh/id_ed25519
        # IdentityFile ~/.ssh/id_ed25519_work
        # IdentitiesOnly yes
    '';
  };

  programs.git = {
    enable = true;

    # Personal defaults
    userName = "Jonas De Meyer";
    userEmail = "43569205+Jonas-D-M@users.noreply.github.com";

    # SSH signing globally
    extraConfig = {
      user.signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      tag.gpgSign = true;
      init.defaultBranch = "master";
      gpg.format = "ssh";
      commit.gpgSign = true;
    };

    # Switch to work identity + work signing key under ~/work/**
    includes = [
      {
        condition = "gitdir:~/work/**";
        path = "~/.gitconfig-work-ssh";
      }
    ];
  };

  # The included work override (identity + signing key)
  home.file.".gitconfig-work-ssh".text = ''
    [user]
      name = Jonas De Meyer
      email = 144120822+Jonas-PRF@users.noreply.github.com
      signingkey = ~/.ssh/id_ed25519_work.pub
    [gpg]
      format = ssh
  '';
}
