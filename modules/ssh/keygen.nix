{
  config,
  pkgs,
  lib,
  ...
}:
let
  keys = config.custom.ssh.keys;
  signers = config.custom.ssh.signers;
  ssh-keygen = "${pkgs.openssh}/bin/ssh-keygen";

  genKeyLine = k: ''gen_key "$HOME/.ssh/${k.name}" ${lib.escapeShellArg k.comment} "${k.type}"'';
  genPubLine = k: ''gen_pub "$HOME/.ssh/${k.name}"'';
  signerBlock = k: ''
    if [ -f "$HOME/.ssh/${k.name}.pub" ]; then
      printf '%s ' ${lib.escapeShellArg k.signs} >> "$tmp_signers"
      cat "$HOME/.ssh/${k.name}.pub" >> "$tmp_signers"
      printf "\n" >> "$tmp_signers"
      wrote_any=true
    fi'';
in
{
  # One activation script driven by the SSH key registry: generate any missing
  # keys (never overwrite), derive their .pub, then assemble allowed_signers.
  # Ordering is line-order within one script — no cross-script DAG dependency.
  home.activation.sshKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    gen_key() {
      keyfile="$1"
      comment="$2"
      keytype="''${3:-ed25519}"
      extra_flags=()
      if [ "$keytype" = "rsa" ]; then
        extra_flags=(-b 4096)
      fi
      if [ ! -f "$keyfile" ]; then
        echo "Generating SSH key ($keytype): $keyfile"
        umask 177
        ${ssh-keygen} -q -t "$keytype" "''${extra_flags[@]}" -N "" -C "$comment" -f "$keyfile"
        chmod 600 "$keyfile"
      else
        echo "Skipping generation: $keyfile already exists"
      fi
    }

    gen_pub() {
      key="$1"; pub="$1.pub"
      if [ -f "$key" ] && [ ! -f "$pub" ]; then
        tmp_pub="$(mktemp)"
        ${ssh-keygen} -y -f "$key" > "$tmp_pub" \
          && install -m 0644 "$tmp_pub" "$pub" \
          || { echo "ssh-keygen failed for $key" >&2; rm -f "$tmp_pub"; exit 1; }
        rm -f "$tmp_pub"
      fi
      [ -f "$pub" ] && chmod 644 "$pub" || true
    }

    # Generate any missing keys (registry order).
    ${lib.concatMapStringsSep "\n    " genKeyLine keys}

    # Derive public keys.
    ${lib.concatMapStringsSep "\n    " genPubLine keys}

    # Assemble allowed_signers from the keys that sign commits.
    tmp_signers="$(mktemp)"; wrote_any=false
    ${lib.concatStringsSep "\n    " (map signerBlock signers)}

    if [ "$wrote_any" = true ]; then
      install -m 0600 "$tmp_signers" "$HOME/.ssh/allowed_signers"
    else
      rm -f "$tmp_signers"
    fi
  '';
}
