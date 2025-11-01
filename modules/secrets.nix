{
  config,
  pkgs,
  lib,
  sops-nix,
  ...
}:
{
  imports = [ sops-nix.homeManagerModules.sops ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  home.activation.ensureSshDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
  '';

  sops.secrets."ssh/id_ed25519" = {
    sopsFile = ./../secrets/ssh.id_ed25519.enc;
    format = "json";
    key = "data";
    path = "${config.home.homeDirectory}/.ssh/id_ed25519";
    mode = "0600";
  };

  sops.secrets."ssh/id_ed25519_work" = {
    sopsFile = ./../secrets/ssh.id_ed25519_work.enc;
    format = "json";
    key = "data";
    path = "${config.home.homeDirectory}/.ssh/id_ed25519_work";
    mode = "0600";
  };

  # Generate .pub files (idempotent) AFTER secrets are installed.
  home.activation.ensurePubKeys = lib.hm.dag.entryAfter [ "sops-install-secrets" ] ''
    # personal
    if [ -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
      ${pkgs.openssh}/bin/ssh-keygen -y -f "$HOME/.ssh/id_ed25519" > "$HOME/.ssh/id_ed25519.pub" || true
      [ -f "$HOME/.ssh/id_ed25519.pub" ] && chmod 644 "$HOME/.ssh/id_ed25519.pub"
    fi
    # work
    if [ -f "$HOME/.ssh/id_ed25519_work" ] && [ ! -f "$HOME/.ssh/id_ed25519_work.pub" ]; then
      ${pkgs.openssh}/bin/ssh-keygen -y -f "$HOME/.ssh/id_ed25519_work" > "$HOME/.ssh/id_ed25519_work.pub" || true
      [ -f "$HOME/.ssh/id_ed25519_work.pub" ] && chmod 644 "$HOME/.ssh/id_ed25519_work.pub"
    fi
  '';
}
