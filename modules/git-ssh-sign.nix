# modules/git-ssh-sign.nix
{ config, lib, ... }:
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
      user.signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519";
      tag.gpgSign = true;
      init.defaultBranch = "master";
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
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
      signingkey = ~/.ssh/id_ed25519_work
    [gpg]
      format = ssh
  '';

  home.activation.generateAllowedSigners =
    lib.hm.dag.entryAfter [ "writeBoundary" "ensurePubKeys" ]
      ''
        set -eu
        mkdir -p "$HOME/.ssh"
        tmp="$(mktemp)"
        if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
          printf "jonas.personal " >> "$tmp"; cat "$HOME/.ssh/id_ed25519.pub" >> "$tmp"; printf "\n" >> "$tmp"
        fi
        if [ -f "$HOME/.ssh/id_ed25519_work.pub" ]; then
          printf "jonas.work " >> "$tmp"; cat "$HOME/.ssh/id_ed25519_work.pub" >> "$tmp"; printf "\n" >> "$tmp"
        fi
        if [ -s "$tmp" ]; then
          mv "$tmp" "$HOME/.ssh/allowed_signers"; chmod 600 "$HOME/.ssh/allowed_signers"
        else
          rm -f "$tmp"
        fi
      '';
}
