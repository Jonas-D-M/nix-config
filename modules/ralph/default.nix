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
# Sandbox settings can be customised in ~/.srt-settings.json
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

    ralph_setup() {
      if [ -f "vendor/bin/sail" ]; then
        RALPH_IS_SAIL=1
        echo "[ralph] Sail project detected — using relaxed sandbox settings."

        # Inject the Docker socket from DOCKER_HOST into the sail settings.
        local docker_sock=""
        if [ -n "$DOCKER_HOST" ]; then
          docker_sock="''${DOCKER_HOST#unix://}"
        elif [ -S /var/run/docker.sock ]; then
          docker_sock="/var/run/docker.sock"
        fi

        RALPH_SRT_SETTINGS=$(mktemp)
        if [ -n "$docker_sock" ]; then
          ${pkgs.jq}/bin/jq --arg sock "$docker_sock" \
            '.network.allowUnixSockets = [$sock]' \
            "$HOME/.srt-settings-sail.json" > "$RALPH_SRT_SETTINGS"
          echo "[ralph] Docker socket: $docker_sock"
          echo "[ralph] Settings:" && cat "$RALPH_SRT_SETTINGS"
        else
          cp "$HOME/.srt-settings-sail.json" "$RALPH_SRT_SETTINGS"
          echo "[ralph] Warning: no Docker socket found — Sail commands may fail."
        fi

        trap 'rm -f "$RALPH_SRT_SETTINGS"' EXIT INT TERM
      else
        RALPH_IS_SAIL=0
        RALPH_SRT_SETTINGS="$HOME/.srt-settings.json"
      fi
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

    ralph_setup
    tool_hint=$(ralph_tool_hint)

    srt --debug --settings "$RALPH_SRT_SETTINGS" claude --dangerously-skip-permissions -p "@PRD.md @progress.txt \
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
      echo "Usage: ralph <iterations>"
      exit 1
    fi

    if [ ! -f "PRD.md" ]; then
      echo "Error: PRD.md not found in current directory."
      echo "Create a PRD.md with your project requirements, then run ralph."
      exit 1
    fi

    touch progress.txt

    ralph_setup
    tool_hint=$(ralph_tool_hint)

    for ((i=1; i<=$1; i++)); do
      echo ""
      echo "=== Ralph iteration $i/$1 ==="
      result=$(srt --debug --settings "$RALPH_SRT_SETTINGS" claude --dangerously-skip-permissions -p "@PRD.md @progress.txt \
      1. Find the highest-priority incomplete task and implement it. \
      2. Run your tests and type checks. \
      3. Update the PRD with what was done. \
      4. Append your progress to progress.txt. \
      5. Commit your changes. \
      ONLY WORK ON A SINGLE TASK. \
      $tool_hint \
      If the PRD is complete, output <promise>COMPLETE</promise>.")

      echo "$result"

      if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
        echo ""
        echo "PRD complete after $i iterations."
        exit 0
      fi
    done
  '';
in
{
  home.packages = [
    sandbox-runtime
    ralph-once
    ralph
  ];

  home.file.".srt-settings.json".source = ./srt-settings.json;
  home.file.".srt-settings-sail.json".source = ./srt-settings-sail.json;
}
