{ pkgs, ... }:
{
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
    "$HOME/.krew/bin"
  ];

  home.sessionVariables = {
    NVM_DIR = "$HOME/.nvm";
    PNPM_HOME = "$HOME/.local/share/pnpm";
    DIRENV_LOG_FORMAT = "";
  };

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    history.ignoreDups = true;
    shellAliases = {
      sail = "sh $([ -f sail ] && echo sail || echo vendor/bin/sail)";
      ls = "eza";
      cd = "z";
      drb = "sudo darwin-rebuild switch --flake ~/nix-config";
    };
    initContent = ''
              # --- NVM bootstrap ---
              [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
              [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

              # --- pnpm path ---
              case ":$PATH:" in
                *":$PNPM_HOME:"*) ;;
                *) export PATH="$PNPM_HOME:$PATH" ;;
              esac

              # --- direnv hook ---
              eval "$(direnv hook zsh)"

              # --- Auto use Node from .nvmrc ---
              autoload -U add-zsh-hook
              load-nvmrc() {
                local nvmrc_path
                nvmrc_path="$(nvm_find_nvmrc)"
                if [ -n "$nvmrc_path" ]; then
                  local nvmrc_node_version
                  nvmrc_node_version=$(nvm version "$(cat "''${nvmrc_path}")")
                  if [ "$nvmrc_node_version" = "N/A" ]; then
                    nvm install
                  elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
                    nvm use
                  fi
                elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
                  echo "Reverting to nvm default version"
                  nvm use default
                fi
              }
              add-zsh-hook chpwd load-nvmrc
              load-nvmrc

              # Keymap & history
              bindkey -e
              bindkey '^p' history-search-backward
              bindkey '^n' history-search-forward

              # Completion styling
              zstyle ':completion:*' matcher-list 'm:{a-z}-={A-Za-z}'
              zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
              zstyle ':completion:*' menu no
              zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

              # Word navigation / undo
              bindkey '^[Oc' forward-word
              bindkey '^[Od' backward-word
              bindkey '^[[1;5D' backward-word
              bindkey '^[[1;5C' forward-word
              bindkey '^H' backward-kill-word
              bindkey '^[[Z' undo
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
