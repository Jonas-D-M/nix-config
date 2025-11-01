{ pkgs, ... }:
{
  # Make common paths available globally (instead of exporting PATH manually)
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
    "$HOME/.krew/bin"
  ];

  # Vars your old zshrc relied on
  home.sessionVariables = {
    NVM_DIR = "$HOME/.nvm";
    PNPM_HOME = "$HOME/.local/share/pnpm";
    DIRENV_LOG_FORMAT = "";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    initExtra = ''
      # --- NVM bootstrap ---
      [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

      # --- pnpm path (as in your zshrc) ---
      case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
      esac

      # --- direnv hook (HM enables direnv, but we keep the shell hook here) ---
      eval "$(direnv hook zsh)"

      # --- Auto use Node from .nvmrc (your function) ---
      autoload -U add-zsh-hook
      load-nvmrc() {
        local nvmrc_path
        nvmrc_path="$(nvm_find_nvmrc)"
        if [ -n "$nvmrc_path" ]; then
          local nvmrc_node_version
          nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
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

      # --- linuxbrew shellenv (harmless if missing) ---
      if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      fi

      # --- fzf keybindings/completion (explicit, like your zshrc) ---
      if command -v fzf >/dev/null 2>&1; then
        eval "$(fzf --zsh)"
      fi

      # --- Zinit bootstrap (as in your zshrc) ---
      if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
          print -P "%F{33}Installing Zinit…%f"
          command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
          command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" || \
              print -P "%F{160}Zinit clone failed.%f"
      fi
      source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
      autoload -Uz _zinit
      (( ${+_comps} )) && _comps[zinit]=_zinit

      # Annexes + plugins you used
      zinit light-mode for \
          zdharma-continuum/zinit-annex-as-monitor \
          zdharma-continuum/zinit-annex-bin-gem-node \
          zdharma-continuum/zinit-annex-patch-dl \
          zdharma-continuum/zinit-annex-rust

      zinit light zsh-users/zsh-syntax-highlighting
      zinit light zsh-users/zsh-completions
      zinit light zsh-users/zsh-autosuggestions
      zinit light Aloxaf/fzf-tab

      # Completions
      autoload -U compinit && compinit

      # Keymap & history (ported)
      bindkey -e
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward

      HISTSIZE=5000
      HISTFILE=$HOME/.zsh_history
      SAVEHIST=$HISTSIZE
      HISTDUP=erase
      setopt appendhistory
      setopt sharehistory
      setopt hist_ignore_space
      setopt hist_ignore_all_dups
      setopt hist_save_no_dups
      setopt hist_ignore_dups
      setopt hist_find_no_dups

      # Completion styling
      zstyle ':completion:*' matcher-list 'm:{a-z}-={A-Za-z}'
      zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

      # Aliases
      alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
      alias ls="eza"
      alias cd="z"

      # Word navigation / undo
      bindkey '^[Oc' forward-word
      bindkey '^[Od' backward-word
      bindkey '^[[1;5D' backward-word
      bindkey '^[[1;5C' forward-word
      bindkey '^H' backward-kill-word
      bindkey '^[[Z' undo
    '';
  };

  # Prompt + smarter cd
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      php = { disabled = false; };
      nodejs = { disabled = false; };
      kubernetes = { disabled = false; };
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
