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

  ralph-once = pkgs.writeShellScriptBin "ralph-once" ''
    #!/usr/bin/env bash
    if [ ! -f "PRD.md" ]; then
      echo "Error: PRD.md not found in current directory."
      echo "Create a PRD.md with your project requirements, then run ralph-once."
      exit 1
    fi
    touch progress.txt
    srt claude --dangerously-skip-permissions "@PRD.md @progress.txt \
    1. Read the PRD and progress file. \
    2. Find the next incomplete task and implement it. \
    3. Commit your changes. \
    4. Update progress.txt with what you did. \
    ONLY DO ONE TASK AT A TIME."
  '';

  ralph = pkgs.writeShellScriptBin "ralph" ''
    #!/usr/bin/env bash
    set -e

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

    for ((i=1; i<=$1; i++)); do
      echo ""
      echo "=== Ralph iteration $i/$1 ==="
      result=$(srt claude --dangerously-skip-permissions -p "@PRD.md @progress.txt \
      1. Find the highest-priority incomplete task and implement it. \
      2. Run your tests and type checks. \
      3. Update the PRD with what was done. \
      4. Append your progress to progress.txt. \
      5. Commit your changes. \
      ONLY WORK ON A SINGLE TASK. \
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
}
