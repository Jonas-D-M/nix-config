#!/usr/bin/env bash
set -euo pipefail

# Cross-platform bootstrap for Linux (Home Manager) and macOS (nix-darwin + HM)
#
# Usage:
#   ./scripts/bootstrap.sh [flakeRef] [bitwardenNoteName]
#
# Defaults:
#   On Linux:     flakeRef => .#jonas-home               (homeConfigurations.*)
#   On macOS:     flakeRef => .#jonas-mac                (darwinConfigurations.*)
#   bitwardenNoteName => age-key
#
# Tip: for headless login, export BW_CLIENTID and BW_CLIENTSECRET and the script
#      will use `bw login --apikey` automatically.

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
IS_DARWIN=false
IS_LINUX=false

case "$OS" in
  darwin) IS_DARWIN=true ;;
  linux)  IS_LINUX=true ;;
  *) echo "❌ Unsupported OS: $OS"; exit 1 ;;
esac

DEFAULT_FLAKE_REF_LINUX=".#jonas-home"
DEFAULT_FLAKE_REF_DARWIN=".#jonas-mac"

if $IS_DARWIN; then
  DEFAULT_FLAKE_REF="$DEFAULT_FLAKE_REF_DARWIN"
else
  DEFAULT_FLAKE_REF="$DEFAULT_FLAKE_REF_LINUX"
fi

FLAKE_REF="${1:-$DEFAULT_FLAKE_REF}"
BW_NOTE_NAME="${2:-age-key}"
AGE_KEYS_PATH="${HOME}/.config/sops/age/keys.txt"

echo "ℹ️  Detected OS: $OS ($ARCH)"
echo "ℹ️  Using flake ref: $FLAKE_REF"

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
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate

  echo "ℹ️  Attempting to load Nix environment for this shell…"

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

  if ! command -v nix >/dev/null 2>&1; then
    echo "⚠️  Nix installation finished, but nix is not yet on PATH."
    echo "    Please open a new terminal/session and re-run this script."
    exit 1
  fi

  echo "✅ Nix installed."
}

ensure_home_manager_hint() {
  if $IS_LINUX && ! command -v home-manager >/dev/null 2>&1; then
    echo "ℹ️  home-manager not found; to init on Linux:"
    echo "    nix run home-manager/master -- init --switch"
  fi
}

apply_activation() {
  # Apply the appropriate system config for the host
  if $IS_DARWIN; then
    # If darwin-rebuild is not yet available (fresh machine), build once and use the result wrapper.
    if ! command -v darwin-rebuild >/dev/null 2>&1; then
      echo "🔧 Building nix-darwin system (first-time on this Mac)…"
      nix build ".#darwinConfigurations.${FLAKE_REF#.#}.system" 2>/dev/null || true
      # Fallback: generic build in case user passed an alias like ".#jonas-mac"
      if [ ! -e "./result/sw/bin/darwin-rebuild" ]; then
        nix build "$FLAKE_REF" 2>/dev/null || true
      fi

      if [ -x "./result/sw/bin/darwin-rebuild" ]; then
        echo "🚀 Activating nix-darwin via build result…"
        ./result/sw/bin/darwin-rebuild switch --flake "$FLAKE_REF"
      else
        # If darwin-rebuild is still not present, try invoking directly (may work if in PATH due to prior installs)
        if command -v darwin-rebuild >/dev/null 2>&1; then
          darwin-rebuild switch --flake "$FLAKE_REF"
        else
          echo "❌ Could not find darwin-rebuild. Ensure your flake defines darwinConfigurations and try again."
          exit 1
        fi
      fi
    else
      echo "🚀 Applying nix-darwin profile: $FLAKE_REF"
      darwin-rebuild switch --flake "$FLAKE_REF"
    fi
  else
    echo "🚀 Applying Home Manager profile: $FLAKE_REF"
    home-manager switch --flake "$FLAKE_REF"
  fi
}

# --- sanity checks -----------------------------------------------------------
if [ ! -f "./flake.nix" ]; then
  echo "❌ Run this from your nix-home repo root (flake.nix not found)."
  exit 1
fi

# Ensure nix is available (installs if missing)
ensure_nix

# Helpful hint for Linux HM init if needed
ensure_home_manager_hint

# --- ephemeral shell: bitwarden + age + (optional) sops ----------------------
# Works on both Linux and macOS since we're using nixpkgs
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

# --- activate (HM on Linux, nix-darwin on macOS) -----------------------------
apply_activation

echo "✅ Done."
if $IS_LINUX; then
  echo "   If shell functions were added, run:  exec \$SHELL"
else
  echo "   If shell functions were added, restart your terminal."
fi
