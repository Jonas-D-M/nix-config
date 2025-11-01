# modules/secrets.nix
{
  config,
  pkgs,
  lib,
  sops-nix,
  ...
}:
{
  # bring in the sops Home Manager module
  imports = [ sops-nix.homeManagerModules.sops ];

  # where your local age private key lives (per host)
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  # ensure ~/.ssh exists with correct perms
  home.activation.ensureSshDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
  '';

  # Decrypt private keys into ~/.ssh (0600)
  # sops.secrets."ssh/id_ed25519" = {
  #   sopsFile = ./../secrets/ssh.id_ed25519.enc;  # committed encrypted file
  #   path = "${config.home.homeDirectory}/.ssh/id_ed25519";
  #   mode = "0600";
  # };

  sops.secrets."ssh/id_ed25519_work" = {
    sopsFile = ./../secrets/ssh.id_ed25519_work.enc;
    format = "json";
    key = "data";
    path = "${config.home.homeDirectory}/.ssh/id_ed25519_work";
    mode = "0600";
  };

  # Generate .pub files from the private keys (idempotent)
  home.activation.ensurePubKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
      ssh-keygen -y -f "$HOME/.ssh/id_ed25519" > "$HOME/.ssh/id_ed25519.pub"
      chmod 644 "$HOME/.ssh/id_ed25519.pub"
    fi
    if [ -f "$HOME/.ssh/id_ed25519_work" ] && [ ! -f "$HOME/.ssh/id_ed25519_work.pub" ]; then
      ssh-keygen -y -f "$HOME/.ssh/id_ed25519_work" > "$HOME/.ssh/id_ed25519_work.pub"
      chmod 644 "$HOME/.ssh/id_ed25519_work.pub"
    fi
  '';
}
