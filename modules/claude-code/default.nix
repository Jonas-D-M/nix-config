{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.claudeCode;

  playSound =
    if pkgs.stdenv.isDarwin then
      "afplay /System/Library/Sounds/Glass.aiff"
    else
      "${lib.getExe' pkgs.pulseaudio "paplay"} /run/current-system/sw/share/sounds/freedesktop/stereo/complete.oga";

  worktreeDeps = pkgs.writeShellScript "worktree-deps" (builtins.readFile ./hooks/worktree-deps.sh);

  gitPushGuard =
    let
      script = pkgs.writeShellApplication {
        name = "git-push-guard";
        runtimeInputs = [
          pkgs.jq
          pkgs.git
        ];
        text = builtins.readFile ./hooks/git-push-guard.sh;
      };
    in
    "${script}/bin/git-push-guard";

  # Vendored, GSD-free statusline (model │ task │ dir │ context bar). Copied
  # into the Nix store so it survives removal of the GSD install under ~/.claude.
  statuslineScript = ''node "${./hooks/statusline.js}"'';

  autoCommitScript = pkgs.writeShellScript "claude-auto-commit" ''
    git rev-parse --git-dir > /dev/null 2>&1 || exit 0
    { ! git diff --quiet || ! git diff --cached --quiet; } || exit 0
    git add -u
    FILES=$(git diff --cached --name-only)
    [ -z "$FILES" ] && exit 0

    DIFF=$(git diff --cached --stat)
    DIFF_CONTENT=$(git diff --cached -- . ':!*.lock' ':!package-lock.json' | head -200)

    PROMPT="You are a commit message generator. Based on this git diff, write a commit message.

    Rules:
    - First line: a concise summary under 72 chars using conventional commit format (feat/fix/refactor/docs/chore)
    - Then a blank line
    - Then a body with bullet points explaining the key changes and WHY they were made
    - Do NOT include Co-Authored-By
    - Output ONLY the commit message, nothing else

    Diff stat:
    $DIFF

    Diff content:
    $DIFF_CONTENT"

    MSG=$(echo "$PROMPT" | ${lib.getExe pkgs.claude-code} --print --model haiku 2>/dev/null)

    if [ -z "$MSG" ] || [ $? -ne 0 ]; then
      COUNT=$(echo "$FILES" | wc -l | tr -d " ")
      SCOPE=$(echo "$FILES" | sed "s|/[^/]*$||" | sort -u | head -1 | awk -F/ '{print $NF}')
      MSG="chore($SCOPE): update $COUNT file(s)"
    fi

    git commit -m "$MSG"
  '';

  settings = {
    includeCoAuthoredBy = false;
    env = {
      # Disable all non-essential network traffic in one flag: session quality
      # surveys, telemetry, Sentry error reporting, the transcript-share
      # follow-up, and the /feedback command. The WebFetch domain safety check
      # is unaffected (it has its own opt-out).
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      # claude-code is pinned by Nix; stop the built-in autoupdater from
      # fighting the package version.
      DISABLE_AUTOUPDATER = "1";
      # Strip Anthropic and cloud-provider credentials from sandboxed Bash
      # subprocess environments so a compromised command cannot read them.
      CLAUDE_CODE_SUBPROCESS_ENV_SCRUB = "1";
    };
    statusLine = {
      type = "command";
      command = statuslineScript;
    };
    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = gitPushGuard;
            }
          ];
        }
      ];
      PostToolUse = [
        {
          matcher = "EnterWorktree";
          hooks = [
            {
              type = "command";
              command = worktreeDeps;
            }
          ];
        }
      ];
      Stop = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = playSound;
            }
          ];
        }
      ];
    };
    sandbox = {
      enabled = true;
      excludedCommands = [
        "nix:*"
        "nix-build:*"
        "nix-shell:*"
        "nix-instantiate:*"
        "darwin-rebuild:*"
        "home-manager:*"
        "brew:*"
        "gh:*"
        # git runs unsandboxed so commit signing can read the private signing
        # key. This keeps the ~/.ssh denyRead below fully intact for every
        # other (less-trusted) command rather than punching a key-exposing
        # hole in it. git is trusted core VCS tooling, like gh above.
        "git:*"
      ]
      ++ lib.optionals cfg.enableDocker [
        "docker:*"
        "docker-compose:*"
        "vendor/bin/sail:*"
        "php:*"
        "composer:*"
      ];
      filesystem = {
        allowWrite = [ "." ] ++ lib.optionals cfg.enableDocker [ cfg.dockerSocket ];
        allowRead = lib.optionals cfg.enableDocker [ cfg.dockerSocket ];
        denyRead = [
          # High-value secrets the default read policy would otherwise expose
          # to any sandboxed subprocess. None of these are needed by Bash, so
          # denying them is pure hardening (esp. the SOPS Age key that decrypts
          # every secret in this repo). Absolute paths so they resolve here
          # rather than under ~/.claude (user-settings relative-path root).
          "~/.ssh"
          "~/.aws"
          "~/.config/sops/age/keys.txt"
          "~/.config/gh"
          "/etc/shadow"
          # NOTE: project .env files are NOT denied here. Bare relative paths in
          # this user-scope settings file resolve under ~/.claude, not the
          # project, so a ".env" entry would protect nothing. To deny a
          # project's .env from sandboxed subprocesses, add a denyRead to that
          # repo's own .claude/settings.json, where "." resolves to its root.
        ];
      };
      network = {
        allowedDomains = [ "*" ];
        # Let sandboxed commands reach localhost on any port (e.g. local dev
        # servers); allowedDomains does not cover loopback by itself.
        allowLocalBinding = true;
      };
    };
    permissions = config.custom.claudeCode._resolvedPermissions;
    extraKnownMarketplaces = {
      mesco = {
        source = {
          source = "github";
          repo = "PRF-FSDT/mesco-claude-plugins";
        };
      };
    };
    enabledPlugins = {
      "mesco-conventions@mesco" = true;
    };
  };
in
{
  imports = [ ./permissions.nix ];

  home.packages = [ pkgs.claude-code ];
  home.file =
    let
      mkSkill = name: {
        ".claude/skills/${name}/SKILL.md".source = ./skills/${name}/SKILL.md;
      };
      mkCommand = name: {
        ".claude/commands/${name}/SKILL.md".source = ./commands/${name}/SKILL.md;
      };
    in
    {
      ".claude/settings.json".text = builtins.toJSON settings;
      ".claude/agents/nix-doctor.md".source = ./agents/nix-doctor.md;
    }
    // mkSkill "nix-flake-patterns"
    // mkSkill "home-manager-modules"
    // mkSkill "darwin-nix-system"
    // mkCommand "nix-check"
    // mkCommand "new-module";
}
