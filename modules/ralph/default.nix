# modules/ralph/default.nix
# Ralph: AI coding agent loop technique
# https://www.aihero.dev/getting-started-with-ralph
#
# Uses sandbox-runtime (srt) for OS-level isolation — no Docker Desktop required.
# https://github.com/anthropic-experimental/sandbox-runtime
#
# Usage:
#   ralph-once          — run one iteration, watch what Claude does
#   ralph <N>           — run up to N iterations autonomously (AFK mode)
#
# Both scripts expect a PRD.md in the current directory.
# progress.txt is created automatically if missing.
#
# Sail projects (vendor/bin/sail present) are auto-detected — srt gets
# relaxed network settings and the prompt switches to Sail commands.
#
# Sandbox settings are generated from commonSettings in this file.
{ pkgs, lib, ... }:

let
  sandbox-runtime = pkgs.buildNpmPackage {
    pname = "sandbox-runtime";
    version = "0.0.42";

    src = pkgs.fetchFromGitHub {
      owner = "anthropic-experimental";
      repo = "sandbox-runtime";
      rev = "v0.0.42";
      # Run `drb` — nix will print the correct hash, then update this value.
      hash = "sha256-aFLHY17wMpSmwpR0GmvBQZ2PL824PTTpfdZQFfR0hBs=";
    };

    # Run `drb` again — nix will print the correct hash, then update this value.
    npmDepsHash = "sha256-K9PttPaNAlPMylndDtNasnN+bgM1DQ3OLyP3aiLxfEQ=";

    meta = {
      description = "OS-level sandboxing for AI agents";
      homepage = "https://github.com/anthropic-experimental/sandbox-runtime";
      license = lib.licenses.mit;
      mainProgram = "srt";
    };
  };

  # Helper sourced by both scripts: detects Sail, builds srt settings, provides tool hints.
  ralph-lib = ''
    RALPH_SRT_SETTINGS=""
    RALPH_ADD_DIR_FLAGS=()

    # ralph_setup [extra-dir...]
    # Resolves extra dirs, patches srt settings, and populates RALPH_ADD_DIR_FLAGS.
    ralph_setup() {
      # Resolve extra dirs to absolute paths.
      local extra_abs=()
      for dir in "$@"; do
        extra_abs+=("$(cd "$dir" && pwd)")
      done

      # Build --add-dir flags for Claude.
      RALPH_ADD_DIR_FLAGS=()
      for abs in "''${extra_abs[@]}"; do
        RALPH_ADD_DIR_FLAGS+=(--add-dir "$abs")
      done

      # Build jq filter to inject extra write paths.
      local extra_json
      extra_json=$(printf '%s\n' "''${extra_abs[@]}" | ${pkgs.jq}/bin/jq -R . | ${pkgs.jq}/bin/jq -sc .)

      local base_settings
      if [ -f "vendor/bin/sail" ]; then
        RALPH_IS_SAIL=1
        echo "[ralph] Sail project detected — using relaxed sandbox settings."

        # Inject the Docker socket from DOCKER_HOST.
        local docker_sock=""
        if [ -n "$DOCKER_HOST" ]; then
          docker_sock="''${DOCKER_HOST#unix://}"
        elif [ -S /var/run/docker.sock ]; then
          docker_sock="/var/run/docker.sock"
        fi

        if [ -n "$docker_sock" ]; then
          base_settings=$(${pkgs.jq}/bin/jq --arg sock "$docker_sock" \
            '.network.allowUnixSockets = [$sock]' \
            "$HOME/.srt-settings-sail.json")
          echo "[ralph] Docker socket: $docker_sock"
        else
          base_settings=$(cat "$HOME/.srt-settings-sail.json")
          echo "[ralph] Warning: no Docker socket found — Sail commands may fail."
        fi
      else
        RALPH_IS_SAIL=0
        base_settings=$(cat "$HOME/.srt-settings.json")
      fi

      # Collect runtime sockets: SSH agent + any already in base settings.
      local ssh_sock="''${SSH_AUTH_SOCK:-}"

      RALPH_SRT_SETTINGS=$(mktemp)
      echo "$base_settings" | ${pkgs.jq}/bin/jq \
        --argjson extra "$extra_json" \
        --arg ssh_sock "$ssh_sock" \
        '
          .filesystem.allowWrite += $extra |
          .allowGitConfig = true |
          if $ssh_sock != "" then
            .network.allowUnixSockets = ((.network.allowUnixSockets // []) + [$ssh_sock] | unique)
          else . end
        ' \
        > "$RALPH_SRT_SETTINGS"

      trap 'rm -f "$RALPH_SRT_SETTINGS"' EXIT INT TERM
    }

    ralph_tool_hint() {
      if [ "$RALPH_IS_SAIL" = "1" ]; then
        echo "Use ./vendor/bin/sail artisan, ./vendor/bin/sail composer, and ./vendor/bin/sail php instead of bare php/composer. Sail services like MySQL and Redis are only reachable from inside the container."
      else
        echo "Use php, composer, and vendor/bin/* directly. NEVER use Docker or Sail."
      fi
    }
  '';

  ralph-once = pkgs.writeShellScriptBin "ralph-once" ''
    #!/usr/bin/env bash
    ${ralph-lib}

    if [ ! -f "PRD.md" ]; then
      echo "Error: PRD.md not found in current directory."
      echo "Create a PRD.md with your project requirements, then run ralph-once."
      exit 1
    fi
    touch progress.txt

    ralph_setup "$@"
    tool_hint=$(ralph_tool_hint)

    srt --settings "$RALPH_SRT_SETTINGS" claude --dangerously-skip-permissions "''${RALPH_ADD_DIR_FLAGS[@]}" -p "@PRD.md @progress.txt \
    1. Read the PRD and progress file. \
    2. Find the next incomplete task and implement it. \
    3. Commit your changes. \
    4. Update progress.txt with what you did. \
    ONLY DO ONE TASK AT A TIME. \
    $tool_hint"
  '';

  ralph = pkgs.writeShellScriptBin "ralph" ''
    #!/usr/bin/env bash
    set -e
    ${ralph-lib}

    if [ -z "$1" ]; then
      echo "Usage: ralph <iterations> [extra-dir...]"
      exit 1
    fi

    iterations=$1
    shift

    if [ ! -f "PRD.md" ]; then
      echo "Error: PRD.md not found in current directory."
      echo "Create a PRD.md with your project requirements, then run ralph."
      exit 1
    fi

    touch progress.txt

    ralph_setup "$@"
    tool_hint=$(ralph_tool_hint)

    tmpout=$(mktemp)
    trap 'rm -f "$tmpout"' EXIT INT TERM

    for ((i=1; i<=iterations; i++)); do
      echo ""
      echo "=== Ralph iteration $i/$iterations ==="
      srt --settings "$RALPH_SRT_SETTINGS" claude --dangerously-skip-permissions "''${RALPH_ADD_DIR_FLAGS[@]}" -p "@PRD.md @progress.txt \
      1. Find the highest-priority incomplete task and implement it. \
      2. Run your tests and type checks. \
      3. Update the PRD with what was done. \
      4. Append your progress to progress.txt. \
      5. Commit your changes. \
      ONLY WORK ON A SINGLE TASK. \
      $tool_hint \
      If the PRD is complete, output \<promise\>COMPLETE\</promise\>." | tee "$tmpout"

      if grep -q "<promise>COMPLETE</promise>" "$tmpout"; then
        echo ""
        echo "PRD complete after $i iterations."
        exit 0
      fi
    done
  '';

  commonSettings = {
    ripgrep.command = "${pkgs.ripgrep}/bin/rg";
    network = {
      allowedDomains = [
        "*.anthropic.com"
        "*.claude.ai"
        "api.github.com"
        "github.com"
        "*.githubusercontent.com"
        "*.npmjs.org"
        "registry.npmjs.org"
      ];
      deniedDomains = [ ];
    };
    filesystem = {
      denyRead = [
        "~/.ssh"
        "~/.gnupg"
        "~/.sops"
      ];
      allowRead = [
        "~/.ssh/known_hosts"
        "~/.ssh/config"
        "~/.ssh/allowed_signers"
        "~/.ssh/*.pub"
      ];
      allowWrite = [
        "."
        "/tmp"
        "/private/tmp"
        "/var/folders"
        "~/.claude"
      ];
      denyWrite = [
        ".env"
        ".env.local"
        ".env.production"
      ];
    };
  };
in
{
  home.packages = [
    sandbox-runtime
    pkgs.ripgrep
    ralph-once
    ralph
  ];

  home.file.".srt-settings.json".text = builtins.toJSON (
    commonSettings
    // {
      network = commonSettings.network // {
        allowLocalBinding = false;
      };
    }
  );

  home.file.".srt-settings-sail.json".text = builtins.toJSON (
    commonSettings
    // {
      allowPty = true;
      enableWeakerNestedSandbox = true;
      network = commonSettings.network // {
        allowLocalBinding = true;
      };
      filesystem = commonSettings.filesystem // {
        allowRead = commonSettings.filesystem.allowRead ++ [
          "~/.colima"
          "~/.docker"
        ];
      };
    }
  );
}
