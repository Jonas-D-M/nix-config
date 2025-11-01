#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/bootstrap.sh [flakeRef] [bitwardenNoteName]
# Defaults:
#   flakeRef: .#jonas-home
#   bitwardenNoteName: "Nix Age Key"
#
# Tip: for headless login, export BW_CLIENTID and BW_CLIENTSECRET and the script
#      will use `bw login --apikey` automatically.

FLAKE_REF="${1:-.#jonas-home}"
BW_NOTE_NAME="${2:-age-key}"
AGE_KEYS_PATH="${HOME}/.config/sops/age/keys.txt"

ensure_nix() {
  if command -v nix >/dev/null 2>&1; then
    return 0
  fi

  echo "❌ nix not found. Installing Nix via Determinate Systems…"
  if ! command -v curl >/dev/null 2>&1; then
    echo "❌ curl is required to install Nix. Please install curl and re-run."
    exit 1
  fi

  # Install Nix (Determinate Systems)
  # Note: This may prompt for sudo on Linux/macOS to set up the multi-user daemon.
  #       We keep going afterwards and try to source the profile so nix is usable immediately.
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate

  echo "ℹ️  Attempting to load Nix environment for this shell…"

  # Try common profile hooks to make nix available in the current process
  # Linux (daemon)
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh || true
  fi
  # Per-user profile (fallback)
  if [ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck disable=SC1091
    . "${HOME}/.nix-profile/etc/profile.d/nix.sh" || true
  fi
  # macOS (daemon)
  if [ -f "/etc/profile.d/nix.sh" ]; then
    # shellcheck disable=SC1091
    . "/etc/profile.d/nix.sh" || true
  fi

  # Final check
  if ! command -v nix >/dev/null 2>&1; then
    echo "⚠️  Nix installation finished, but nix is not yet on PATH."
    echo "    Please open a new terminal/session and re-run this script."
    exit 1
  fi

  echo "✅ Nix installed."
}

# --- sanity checks -----------------------------------------------------------
if [ ! -f "./flake.nix" ]; then
  echo "❌ Run this from your nix-home repo root (flake.nix not found)."
  exit 1
fi

# Ensure nix is available (installs if missing)
ensure_nix

# home-manager must exist; if HM missing, suggest init
if ! command -v home-manager >/dev/null 2>&1; then
  echo "ℹ️ home-manager not found; you can install it with:"
  echo "   nix run home-manager/master -- init --switch"
fi

# --- ephemeral shell: bitwarden + age + (optional) sops ----------------------
nix shell nixpkgs#bitwarden-cli nixpkgs#age nixpkgs#sops -c bash -lc "
  set -euo pipefail

  # 1) Bitwarden login (API key if provided, else interactive)
  if [ -n \"\${BW_CLIENTID:-}\" ] && [ -n \"\${BW_CLIENTSECRET:-}\" ]; then
    echo '🔐 Logging in to Bitwarden with API key...'
    bw login --apikey >/dev/null
  else
    echo '🔐 Logging in to Bitwarden...'
    bw login >/dev/null
  fi

  # 2) Unlock and export BW_SESSION for this subshell only
  echo '🔓 Unlocking Bitwarden vault...'
  export BW_SESSION=\"\$(bw unlock --raw)\"

  # 3) Restore Age key from Secure Note into ~/.config/sops/age/keys.txt
  echo '📥 Restoring Age key from Bitwarden note: \"${BW_NOTE_NAME}\"'
  mkdir -p \"$(dirname "${AGE_KEYS_PATH}")\"
  bw get notes \"${BW_NOTE_NAME}\" > \"${AGE_KEYS_PATH}\"
  chmod 600 \"${AGE_KEYS_PATH}\"

  echo '🔎 Age public recipient:'
  age-keygen -y \"${AGE_KEYS_PATH}\" || true

  # 4) Optional quick validation: try to decrypt one secret if present
  if [ -f secrets/ssh.id_ed25519.enc ]; then
    echo '🧪 Testing decryption of secrets/ssh.id_ed25519.enc ...'
    sops -d secrets/ssh.id_ed25519.enc >/dev/null && echo '✅ Decryption OK'
  fi
"

# --- run HM once (keys are present now, sops-nix can decrypt) ----------------
echo "🚀 Applying Home Manager profile: ${FLAKE_REF}"
home-manager switch --flake "${FLAKE_REF}"

echo "✅ Done. If shell functions (e.g. bw-unlock) were added, run:  exec zsh"
