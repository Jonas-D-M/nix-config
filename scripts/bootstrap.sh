#!/usr/bin/env bash
# Re-exec under bash if we're not already in bash (avoids sh/dash errors)
if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

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

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
IS_DARWIN=false
IS_LINUX=false

case "$OS" in
  darwin) IS_DARWIN=true ;;
  linux)  IS_LINUX=true ;;
  *) echo "❌ Unsupported OS: $OS"; exit 1 ;;
esac

DEFAULT_FLAKE_REF_LINUX=".#jonas"
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

# --- helpers to make Nix usable in THIS process --------------------------------
set_nix_env_for_current_shell() {
  local daemon_profile="/nix/var/nix/profiles/default"
  local bin1="$daemon_profile/bin"
  local bin2="$daemon_profile/sw/bin"

  if [ -d "$bin1" ] || [ -d "$bin2" ]; then
    export PATH="${bin1}:${bin2}:${PATH}"
  fi

  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh || true
  fi
  if [ -f /etc/profile.d/nix.sh ]; then
    # shellcheck disable=SC1091
    . /etc/profile.d/nix.sh || true
  fi
  if [ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck disable=SC1091
    . "${HOME}/.nix-profile/etc/profile.d/nix.sh" || true
  fi

  if $IS_DARWIN && [ -n "${ZSH_VERSION:-}" ]; then
    if [ -f /etc/zshrc ]; then . /etc/zshrc || true; fi
    if [ -d /etc/zshrc.d ]; then
      for f in /etc/zshrc.d/*.zsh; do . "$f" || true; done
    fi
  fi
}

pick_nix_cmd() {
  if command -v nix >/dev/null 2>&1; then
    echo "nix"; return
  fi
  if [ -x /nix/var/nix/profiles/default/bin/nix ]; then
    echo "/nix/var/nix/profiles/default/bin/nix"; return
  fi
  echo "nix"
}

ensure_nix() {
  if command -v nix >/dev/null 2>&1 || [ -x /nix/var/nix/profiles/default/bin/nix ]; then
    set_nix_env_for_current_shell
    return 0
  fi

  echo "❌ nix not found. Installing Nix via Determinate Systems…"
  if ! command -v curl >/dev/null 2>&1; then
    echo "❌ curl is required to install Nix. Please install curl and re-run."
    exit 1
  fi

  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate

  echo "ℹ️  Loading Nix environment for this shell…"
  set_nix_env_for_current_shell

  if ! command -v nix >/dev/null 2>&1 && [ ! -x /nix/var/nix/profiles/default/bin/nix ]; then
    echo "⚠️  Nix installed, but not on PATH yet."
    echo "   Open a new terminal OR run:  exec \$SHELL -l"
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
  if $IS_DARWIN; then
    if ! command -v darwin-rebuild >/dev/null 2>&1; then
      local host_attr="${FLAKE_REF#.#}"
      echo "🔧 Building nix-darwin system attr: .#darwinConfigurations.${host_attr}.system"
      "${NIX_CMD}" build ".#darwinConfigurations.${host_attr}.system" 2>/dev/null || true
      if [ ! -e "./result/sw/bin/darwin-rebuild" ]; then
        "${NIX_CMD}" build "$FLAKE_REF" 2>/dev/null || true
      fi
      if [ -x "./result/sw/bin/darwin-rebuild" ]; then
        echo "🚀 Activating nix-darwin via build result…"
        ./result/sw/bin/darwin-rebuild switch --flake "$FLAKE_REF"
      else
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

ensure_nix
set_nix_env_for_current_shell
NIX_CMD="$(pick_nix_cmd)"
ensure_home_manager_hint

# --- Bitwarden + age + sops (idempotent, no outer-shell expansions) ----------
BW_NOTE_NAME="$BW_NOTE_NAME" AGE_KEYS_PATH="$AGE_KEYS_PATH" \
"${NIX_CMD}" shell nixpkgs#bitwarden-cli nixpkgs#age nixpkgs#sops nixpkgs#jq -c bash -lc '
  set -euo pipefail

  # Local copies of env vars
  note="${BW_NOTE_NAME}"
  keys_path="${AGE_KEYS_PATH}"

  # 1) Status -> login/unlock only if needed
  bw_json="$(bw status --raw 2>/dev/null || echo "{\"status\":\"unknown\"}")"
  status="$(printf "%s" "$bw_json" | jq -r ".status")"

  case "$status" in
    unauthenticated|unknown)
      if [ -n "${BW_CLIENTID:-}" ] && [ -n "${BW_CLIENTSECRET:-}" ]; then
        echo "🔐 Logging in to Bitwarden with API key…"
        bw login --apikey >/dev/null
      else
        echo "🔐 Logging in to Bitwarden…"
        bw login >/dev/null
      fi
      ;;
    locked)
      echo "🔓 Vault is locked; will unlock…"
      ;;
    unlocked)
      echo "✅ Bitwarden already unlocked."
      ;;
    *)
      echo "ℹ️ Bitwarden status: $status"
      ;;
  esac

  # 2) Ensure unlocked; capture BW_SESSION (ok if already unlocked)
  if [ "$status" != "unlocked" ]; then
    echo "🔓 Unlocking Bitwarden vault…"
    export BW_SESSION="$(bw unlock --raw)"
  else
    export BW_SESSION="$(bw unlock --raw || true)"
  fi

  # 3) Restore Age key
  echo "📥 Restoring Age key from Bitwarden note: \"$note\""
  mkdir -p "$(dirname "$keys_path")"
  bw get notes "$note" > "$keys_path"
  chmod 600 "$keys_path"

  echo "🔎 Age public recipient:"
  age-keygen -y "$keys_path" || true

  # 4) Optional quick validation
  if [ -f secrets/ssh.id_ed25519.enc ]; then
    echo "🧪 Testing decryption of secrets/ssh.id_ed25519.enc …"
    if sops -d secrets/ssh.id_ed25519.enc >/dev/null; then
      echo "✅ Decryption OK"
    else
      echo "⚠️  Decryption failed (check keys / recipients)."
    fi
  fi
'

# --- activate (HM on Linux, nix-darwin on macOS) -----------------------------
apply_activation

echo "✅ Done."
if $IS_DARWIN; then
  if [ -t 1 ]; then
    echo "🔄 Reloading your login shell so Nix/nix-darwin are on PATH…"
    exec "$SHELL" -l
  fi
else
  echo "   If shell functions were added, run:  exec \$SHELL -l"
fi
