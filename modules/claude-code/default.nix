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
    model = "default";
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
          ".env"
          ".env.local"
          ".env.development"
          ".env.production"
          ".env.staging"
          ".env.test"
          "/etc/shadow"
        ];
      };
      network = {
        allowedDomains = [ "*" ];
      };
    };
    permissions = config.custom.claudeCode._resolvedPermissions;
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
