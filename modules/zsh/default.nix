{ pkgs, config, ... }:
{
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
    "$HOME/.krew/bin"
  ];

  home.sessionVariables = {
    NVM_DIR = "$HOME/.node-version";
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
      hms = "home-manager switch --flake ~/nix-config";
      drb = "sudo darwin-rebuild switch --flake ~/nix-config";

      neofetch = "fastfetch";
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

      # --- fnm (Fast Node Manager) ---
      eval "$(fnm env --use-on-cd --shell zsh)"

      load-nvmrc() {
        DEFAULT_NODE_VERSION="$(fnm ls | awk '/default/{print $2}')"
        CURRENT_NODE_VERSION="$(fnm current)"
        REQUIRED_NODE_VERSION=""

        if [[ -f .nvmrc && -r .nvmrc ]]; then
          REQUIRED_NODE_VERSION="$(cat .nvmrc)"

          if [[ $CURRENT_NODE_VERSION != $REQUIRED_NODE_VERSION ]]; then
            echo "Reverting to node from \"$CURRENT_NODE_VERSION\" to \"$REQUIRED_NODE_VERSION\""

            if fnm ls | grep -q $REQUIRED_NODE_VERSION; then
              fnm use $REQUIRED_NODE_VERSION
            else
              echo "Node version $REQUIRED_NODE_VERSION not found. Installing..."
              fnm install $REQUIRED_NODE_VERSION
              fnm use $REQUIRED_NODE_VERSION
            fi
          fi
        else
          if [[ $CURRENT_NODE_VERSION != $DEFAULT_NODE_VERSION ]]; then
            echo "Reverting to default node version: $DEFAULT_NODE_VERSION"
            fnm use $DEFAULT_NODE_VERSION
          fi
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
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;3C' forward-word
      bindkey '^[Od' backward-word
      bindkey '^[[1;3D' backward-word
      bindkey '^[[1;5D' backward-word
      bindkey '^H' backward-kill-word
      bindkey '^[[Z' undo
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
