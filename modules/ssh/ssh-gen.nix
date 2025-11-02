{
  config,
  pkgs,
  lib,
  ...
}:
let
  homeDir = config.home.homeDirectory;
in
{
  # Ensure ~/.ssh exists
  home.activation.ensureSshDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
  '';

  # Generate keys if they don't exist (never overwrite)
  home.activation.generateSshKeys = lib.hm.dag.entryAfter [ "ensureSshDir" ] ''
    set -euo pipefail

    gen_key() {
      keyfile="$1"
      comment="$2"
      if [ ! -f "$keyfile" ]; then
        echo "Generating SSH key: $keyfile"
        umask 177
        ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C "$comment" -f "$keyfile"
        chmod 600 "$keyfile"
      else
        echo "Skipping generation: $keyfile already exists"
      fi
    }

    gen_key "$HOME/.ssh/id_ed25519" "jonas.personal"
    gen_key "$HOME/.ssh/id_ed25519_work" "jonas.work"
  '';

  # Create .pub and allowed_signers from the keys
  home.activation.ensurePubKeys = lib.hm.dag.entryAfter [ "generateSshKeys" ] ''
    set -euo pipefail

    gen_pub() {
      key="$1"; pub="$1.pub"
      if [ -f "$key" ] && [ ! -f "$pub" ]; then
        tmp_pub="$(mktemp)"
        ${pkgs.openssh}/bin/ssh-keygen -y -f "$key" > "$tmp_pub" \
          && install -m 0644 "$tmp_pub" "$pub" \
          || { echo "ssh-keygen failed for $key" >&2; rm -f "$tmp_pub"; exit 1; }
        rm -f "$tmp_pub"
      fi
      [ -f "$pub" ] && chmod 644 "$pub" || true
    }

    gen_pub "$HOME/.ssh/id_ed25519"
    gen_pub "$HOME/.ssh/id_ed25519_work"

    tmp_signers="$(mktemp)"; wrote_any=false
    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
      printf "jonas.personal " >> "$tmp_signers"
      cat "$HOME/.ssh/id_ed25519.pub" >> "$tmp_signers"
      printf "\n" >> "$tmp_signers"
      wrote_any=true
    fi
    if [ -f "$HOME/.ssh/id_ed25519_work.pub" ]; then
      printf "jonas.work " >> "$tmp_signers"
      cat "$HOME/.ssh/id_ed25519_work.pub" >> "$tmp_signers"
      printf "\n" >> "$tmp_signers"
      wrote_any=true
    fi

    if [ "$wrote_any" = true ]; then
      install -m 0600 "$tmp_signers" "$HOME/.ssh/allowed_signers"
    else
      rm -f "$tmp_signers"
    fi
  '';
}
