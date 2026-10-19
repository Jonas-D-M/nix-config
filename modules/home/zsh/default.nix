# modules/home/zsh/default.nix
# The shell: zsh with syntax highlighting and autosuggestions, plus starship,
# zoxide (`cd` -> `z`), eza (`ls` -> `eza`) and fzf. Owns the shell aliases
# (drb, hms, nix-cleanup, sail, git shorthands), keybindings, fnm init, and
# session PATH additions (~/.krew/bin, ~/.local/bin, ~/bin).
#
# The config is split in two layers so Claude Code's shells (which set
# $CLAUDECODE) get the environment but none of the interactive niceties:
#   - environment: home.sessionPath / home.sessionVariables, plus `fnm env`
#     and the direnv hook; always loaded.
#   - interactive: prompt, plugins, completion, keybindings, aliases; collected
#     in `custom.zsh.interactiveInit` and skipped when $CLAUDECODE is set.
# Home Manager's own zsh integrations (shellAliases, syntaxHighlighting,
# autosuggestion, completionInit, programs.*.enableZshIntegration) emit their
# lines unconditionally, so they stay off and are re-added here instead.
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.custom.zsh;

  aliases = {
    sail = "sh $([ -f sail ] && echo sail || echo vendor/bin/sail)";
    cd = "z";
    hms = "home-manager switch --flake ~/nix-config";
    drb = "sudo darwin-rebuild switch --flake ~/nix-config";
    neofetch = "fastfetch";
    nix-cleanup = "nix-collect-garbage --delete-older-than 30d";
    kloot = "claude";

    # eza (what programs.eza.enableZshIntegration would add)
    ls = "eza";
    ll = "eza -l";
    la = "eza -a";
    lt = "eza --tree";
    lla = "eza -la";

    # git
    gd = "git diff";
    gdc = "git diff --cached";
    gs = "git status --short";
    ga = "git add -vu";
    gA = "git add -vA";
    gc = "git commit";
    gcm = "git commit -m";
    gca = "git commit -a";
    gcam = "git commit -am";
    gco = "git checkout";
    gcob = "git checkout -b";
    gp = "git pull";
    gpp = "git pull && git push";
    gl = ''git log --graph --abbrev-commit --decorate --date=relative --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)" --all'';
  };
in
{
  options.custom.zsh.interactiveInit = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = ''
      zsh init code for interactive use only (prompt, plugins, completion,
      keybindings, aliases). Emitted into .zshrc inside a guard that skips it
      when $CLAUDECODE is set. Use lib.mkOrder to position snippets.
    '';
  };

  config = {
    home.sessionVariables = {
      _ZO_DOCTOR = "0";
      # EDITOR is owned by the vscode module.
    };

    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/bin"
      "$HOME/.krew/bin"
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      "/Applications/Obsidian.app/Contents/MacOS"
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
    ];

    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      # Keep the completion packages and fpath setup; compinit itself runs in
      # the interactive layer.
      enableCompletion = true;
      completionInit = "";
      history.ignoreDups = true;
      initContent = lib.mkMerge [
        ''
          # --- fnm (Fast Node Manager) ---
          eval "$(fnm env --use-on-cd --shell zsh)"
        ''
        # Before fnm and direnv (order 1000), so the starship and zoxide
        # hooks register ahead of theirs, as Home Manager would order them.
        (lib.mkOrder 990 ''
          if [[ -z "$CLAUDECODE" ]]; then
          ${cfg.interactiveInit}
          fi
        '')
      ];
    };

    custom.zsh.interactiveInit = lib.mkMerge [
      (lib.mkOrder 500 ''
        autoload -U compinit && compinit
      '')

      (lib.mkOrder 600 ''
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        ZSH_AUTOSUGGEST_STRATEGY=(history)
      '')

      (lib.mkOrder 700 ''
        eval "$(${lib.getExe config.programs.zoxide.package} init zsh)"
      '')

      (lib.mkOrder 800 ''
        if [[ $options[zle] = on ]]; then
          source <(${lib.getExe config.programs.fzf.package} --zsh)
        fi
      '')

      ''
        # Keymap & history
        # bindkey -e
        bindkey '^p' history-search-backward
        bindkey '^n' history-search-forward

        # Completion styling
        zstyle ':completion:*' matcher-list 'm:{a-z}-={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

        # Word navigation / undo
        bindkey '^[Oc' forward-word
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;3C' forward-word
        bindkey '^[Od' backward-word
        bindkey '^[[1;3D' backward-word
        bindkey '^[[1;5D' backward-word
        bindkey '^H' backward-kill-word
        bindkey '^[[Z' undo
        bindkey '^[[3~' delete-char
        bindkey '^[[3;3~' kill-word
      ''

      (lib.mkOrder 1900 ''
        if [[ $TERM != "dumb" ]]; then
          eval "$(${lib.getExe config.programs.starship.package} init zsh)"
        fi
      '')

      (lib.mkOrder 1950 (
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}") aliases
        )
        + "\n"
      ))

      # Load zsh-syntax-highlighting after all custom widgets have been created.
      (lib.mkOrder 2000 ''
        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
      '')
    ];

    programs.fzf = {
      enable = true;
      enableZshIntegration = false;
    };

    programs.eza = {
      enable = true;
      enableZshIntegration = false;
    };

    programs.starship = {
      enable = true;
      enableZshIntegration = false;
      settings = {
        "$schema" = "https://starship.rs/config-schema.json";
        right_format = "$time";

        add_newline = true;

        command_timeout = 2000;

        character = {
          success_symbol = "[➜](bold green)";
        };

        package = {
          disabled = true;
        };
        time = {
          disabled = false;
        };
        direnv = {
          disabled = false;
        };
      };
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = false;
    };
  };
}
