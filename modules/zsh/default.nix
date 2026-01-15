{ pkgs, config, ... }:
{
  home.sessionVariables = {
    PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
    "$HOME/.krew/bin"
    "$HOME/.local/share/pnpm"
  ];

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    history.ignoreDups = true;
    sessionVariables = {
      PNPM_HOME = "$HOME/.local/share/pnpm";
      DIRENV_LOG_FORMAT = "";
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.sops/age-key.txt";
    };
    shellAliases = {
      sail = "sh $([ -f sail ] && echo sail || echo vendor/bin/sail)";
      ls = "eza";
      cd = "z";
      hms = "home-manager switch --flake ~/nix-config";
      drb = "sudo darwin-rebuild switch --flake ~/nix-config";
      neofetch = "fastfetch";
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

  home.packages = with pkgs; [
    fnm
    pnpm
  ];

  home.file = {
    ".nvmrc" = {
      text = "20\n";
      target = "${config.home.homeDirectory}/.nvmrc";
    };
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
