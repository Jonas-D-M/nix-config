{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.sessionVariables = {
    _ZO_DOCTOR = "0";
    # EDITOR is owned by the neovim module.
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
    "$HOME/.krew/bin"
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    "/Applications/Obsidian.app/Contents/MacOS"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    history.ignoreDups = true;
    shellAliases = {
      sail = "sh $([ -f sail ] && echo sail || echo vendor/bin/sail)";
      ls = "eza";
      cd = "z";
      hms = "home-manager switch --flake ~/nix-config";
      drb = "sudo darwin-rebuild switch --flake ~/nix-config";
      neofetch = "fastfetch";
      nix-cleanup = "nix-collect-garbage --delete-older-than 30d";
      kloot = "claude";

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
    initContent = ''
      # --- fnm (Fast Node Manager) ---
      eval "$(fnm env --use-on-cd --shell zsh)"

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

    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
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
    enableZshIntegration = true;
  };

}
