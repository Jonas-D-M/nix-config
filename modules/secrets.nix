{
  config,
  pkgs,
  lib,
  sops-nix,
  ...
}:
let
  # Align Darwin home path with flake (jonasdemeyer) to avoid path mismatches during activation.
  homeDir = if pkgs.stdenv.isDarwin then "/Users/jonasdemeyer" else "/home/jonas";
in
{
  # Bring in sops-nix for Home Manager
  imports = [ sops-nix.homeManagerModules.sops ];
  sops.age.keyFile = lib.mkDefault "${homeDir}/.config/sops/age/keys.txt";

  # Example wiring for future secrets
  # sops.defaultSopsFile = ./secrets.yaml;
  # sops.secrets."gh_token".path = "${homeDir}/.config/github/token";

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

  # Generate .pub and allowed_signers after secrets are installed.
  home.activation.ensurePubKeys = lib.hm.dag.entryAfter [ "ensureSshDir" "sops-nix" ] ''
    set -euo pipefail

    gen_pub() {
      key="$1"; pub="$1.pub"
      if [ -f "$key" ] && [ ! -f "$pub" ]; then
        tmp_pub="$(mktemp)"
        ${pkgs.openssh}/bin/ssh-keygen -y -f "$key" > "$tmp_pub" && install -m 0644 "$tmp_pub" "$pub" || {
          echo "ssh-keygen failed for $key" >&2; rm -f "$tmp_pub"; exit 1; }
        rm -f "$tmp_pub"
      fi
    }

    gen_pub "$HOME/.ssh/id_ed25519"
    gen_pub "$HOME/.ssh/id_ed25519_work"

    tmp_signers="$(mktemp)"; wrote_any=false
    [ -f "$HOME/.ssh/id_ed25519.pub" ] && { printf "jonas.personal " >> "$tmp_signers"; cat "$HOME/.ssh/id_ed25519.pub" >> "$tmp_signers"; printf "\n" >> "$tmp_signers"; wrote_any=true; }
    [ -f "$HOME/.ssh/id_ed25519_work.pub" ] && { printf "jonas.work " >> "$tmp_signers"; cat "$HOME/.ssh/id_ed25519_work.pub" >> "$tmp_signers"; printf "\n" >> "$tmp_signers"; wrote_any=true; }
    [ "$wrote_any" = true ] && install -m 0600 "$tmp_signers" "$HOME/.ssh/allowed_signers" || rm -f "$tmp_signers"
  '';
}
