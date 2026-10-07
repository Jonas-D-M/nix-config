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
    # No attribution in commits or PRs. The deprecated includeCoAuthoredBy =
    # false only blanked the Co-Authored-By trailer and PR footer; sessions
    # connected to claude.ai (Remote Control / web) still appended a
    # `Claude-Session: <url>` trailer and a PR-body session link, which only
    # sessionUrl = false suppresses.
    attribution = {
      commit = "";
      pr = "";
      sessionUrl = false;
    };
    # Declared here as the default model. The makeClaudeSettingsMutable
    # activation script below writes settings.json as a real writable file
    # (not a store symlink), so in-app writes like /model edit it in place
    # without clobbering the rest of this attrset; the next rebuild restores
    # this declared value.
    model = "claude-opus-5[1m]";
    env = {
      # Disable all non-essential network traffic in one flag: session quality
      # surveys, telemetry, Sentry error reporting, the transcript-share
      # follow-up, and the /feedback command. The WebFetch domain safety check
      # is unaffected (it has its own opt-out).
      #
      # It costs more than the name suggests, though: it also skips the startup
      # GET /api/claude_cli/bootstrap, and disables /design-sync, Projects, and
      # --enable-live-preview. See ANTHROPIC_DEFAULT_FABLE_MODEL below for the
      # bootstrap fallout and its workaround.
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      # Without the bootstrap fetch above, additionalModelOptionsCache in
      # ~/.claude.json is never populated -- and that cache is the only thing
      # the /model picker consults to decide whether the account may use Fable.
      # An empty cache reads as "not entitled", so every fable entry is
      # filtered out of the list even though the account can use the model
      # fine. Setting this env var takes the picker's early-exit path and
      # restores `fable` / `fable[1m]`. The value is the CLI's own default for
      # the family, so it pins nothing that was not already pinned.
      ANTHROPIC_DEFAULT_FABLE_MODEL = "claude-fable-5";
      # claude-code is pinned by Nix; stop the built-in autoupdater from
      # fighting the package version.
      DISABLE_AUTOUPDATER = "1";
      # Sandboxed Bash can only reach the network through the sandbox proxy
      # (HTTPS_PROXY), but Node's built-in fetch ignores proxy env vars unless
      # this is set -- it resolves DNS directly, which the sandbox blocks
      # (ENOTFOUND). pnpm 11's pre-exec registry signature check uses it, so
      # every `pnpm exec` failed with ERR_PNPM_PNPM_ENGINE_IDENTITY_UNVERIFIABLE
      # despite allowedDomains = [ "*" ]. Inert when no proxy var is set.
      NODE_USE_ENV_PROXY = "1";
      # NOTE: do not set CLAUDE_CODE_SUBPROCESS_ENV_SCRUB here. It looks like a
      # free hardening win (it strips Anthropic/cloud credentials from sandboxed
      # Bash subprocess environments), but the CLI treats it as an
      # untrusted-multi-user signal and short-circuits permission-mode
      # resolution to "default" before permissions.defaultMode is ever read --
      # silently, when the mode comes from settings rather than a CLI flag. That
      # killed the `defaultMode = "auto"` set in ./permissions.nix. There is no
      # settings-level way to keep both. Nothing is lost by omitting it: auth
      # here is the OAuth credentials file, not ANTHROPIC_*/AWS_* env vars, so
      # there is nothing in the environment to scrub. The file-based secrets
      # (~/.ssh, ~/.aws, the SOPS Age key) are protected by
      # sandbox.credentials below, which is a separate mechanism.
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
      # Space-glob patterns ("git *"), NOT the permission-rule "git:*" form --
      # the colon form silently matches nothing, so every command stayed
      # sandboxed. An exclusion only applies when every segment of a compound
      # command (&&, ;, |) matches; `git add . && git commit` does, `... | head`
      # does not. The matcher is stricter than that, too: a leading `cd`, any
      # redirect, `git -C <dir>`, and `$(...)` substitution (the stock
      # `git commit -m "$(cat <<'EOF' ...)"` form) all keep a call sandboxed.
      #
      # Every entry runs with full access, so each one is a tool that cannot
      # work in the sandbox, narrowed to the subcommands that need to leave
      # it. Interpreters and tools that execute files from the working
      # directory (php, composer, docker compose, nix run/develop/shell -c) are
      # deliberately absent: Claude could write the file and then run it
      # unsandboxed. Those fall back to the unsandboxed retry, which auto mode's
      # classifier reviews.
      excludedCommands = [
        # Nix talks to the daemon over a Unix socket the sandbox blocks.
        "nix build *"
        "nix eval *"
        "nix flake *"
        "nix search *"
        "nix path-info *"
        "nix log *"
        "nix why-depends *"
        "nix store *"
        "nix-build *"
        "nix-instantiate *"
        "darwin-rebuild *"
        "home-manager *"
        "brew *"
        # Go CLI: fails TLS verification under Seatbelt (x509 OSStatus -26276).
        "gh *"
        # git subcommands that sign (commit.gpgsign reads ~/.ssh, denied
        # below) or talk to an SSH remote (the macOS sandbox tunnel can't
        # authenticate to its proxy). Everything else -- status, diff, add,
        # log, checkout -- stays sandboxed.
        "git commit *"
        "git tag *"
        "git merge *"
        "git rebase *"
        "git cherry-pick *"
        "git revert *"
        "git push *"
        "git fetch *"
        "git pull *"
        "git clone *"
        "git ls-remote *"
        "git submodule *"
      ];
      filesystem = {
        allowWrite = [ "." ];
      };
      # High-value secrets the default read policy would otherwise expose to
      # any sandboxed subprocess. `deny` blocks reads inside the sandbox (same
      # effect as filesystem.denyRead), and deny entries merge across settings
      # scopes, so no project settings can lift them. Absolute/~ paths so they
      # resolve here rather than under ~/.claude (user-settings relative root).
      #
      # ~/.config/gh is deliberately NOT here: gh keeps its tokens in the macOS
      # keychain, so the directory holds no secrets.
      #
      # Project .env files aren't either: a relative path in this user-scope
      # file resolves under ~/.claude. Deny them from a repo's own
      # .claude/settings.json, where "." resolves to its root.
      credentials.files =
        map
          (path: {
            inherit path;
            mode = "deny";
          })
          [
            "~/.ssh"
            "~/.aws"
            "~/.config/sops/age/keys.txt"
            "/etc/shadow"
          ];
      network = {
        # Registries and forges every project needs, so routine installs and
        # fetches don't stop for review. Anything else goes through auto mode's
        # per-command allowed domains, which the classifier reviews.
        allowedDomains = [
          "github.com"
          "*.github.com"
          "*.githubusercontent.com"
          "registry.npmjs.org"
          "registry.yarnpkg.com"
          "packagist.org"
          "*.packagist.org"
          "cache.nixos.org"
          "channels.nixos.org"
          "*.cachix.org"
        ];
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

  # HM would otherwise link ~/.claude/settings.json to a read-only store path.
  # Claude writes settings in-app (e.g. /model), and against a read-only
  # symlink it unlinks and replaces the file with just its own view, wiping
  # the HM-managed keys (statusline, hooks, permissions) until the next
  # rebuild. Swap the symlink for a writable copy so in-app writes edit it in
  # place; the next rebuild restores the declared values. Mirrors the VSCode
  # makeVscodeSettingsMutable pattern.
  home.activation.makeClaudeSettingsMutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    run rm -f "$settings.hm-backup"
    if [ -L "$settings" ]; then
      target=$(readlink "$settings")
      run rm "$settings"
      run cp "$target" "$settings"
      run chmod u+w "$settings"
    fi
  '';
}
