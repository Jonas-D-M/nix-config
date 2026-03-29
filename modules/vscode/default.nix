{
  pkgs,
  lib,
  vscode-marketplace-release,
  ...
}:
{
  programs.vscode = {
    enable = true;
    package = lib.mkIf pkgs.stdenv.isDarwin (
      lib.mkForce (
        pkgs.emptyDirectory
        // {
          pname = "vscode";
          version = "0.0.0";
        }
      )
    );
    mutableExtensionsDir = true;

    profiles.default = {
      extensions =
        (with vscode-marketplace-release; [
          aaron-bond.better-comments
          ahmadawais.shades-of-purple
          alexcvzz.vscode-sqlite
          anthropic.claude-code
          bbenoist.nix
          beardedbear.beardedtheme
          bmewburn.vscode-intelephense-client
          bradlc.vscode-tailwindcss
          christian-kohler.npm-intellisense
          christian-kohler.path-intellisense
          codingyu.laravel-goto-view
          dbaeumer.vscode-eslint
          docker.docker
          donjayamanne.githistory
          dsznajder.es7-react-js-snippets
          eamodio.gitlens
          editorconfig.editorconfig
          enkia.tokyo-night
          esbenp.prettier-vscode
          github.copilot-chat
          github.vscode-github-actions
          github.vscode-pull-request-github
          humao.rest-client
          jasonnutter.search-node-modules
          jnoortheen.nix-ide
          jock.svg
          jundat95.react-native-snippet
          mads-hartmann.bash-ide-vscode
          mrmlnc.vscode-scss
          ms-azuretools.vscode-azureresourcegroups
          ms-azuretools.vscode-containers
          ms-azuretools.vscode-docker
          ms-edgedevtools.vscode-edge-devtools
          ms-kubernetes-tools.vscode-kubernetes-tools
          ms-playwright.playwright
          ms-python.autopep8
          ms-python.debugpy
          ms-python.python
          ms-python.vscode-pylance
          ms-python.vscode-python-envs
          ms-vscode-remote.remote-containers
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-ssh-edit
          ms-vscode-remote.remote-wsl
          ms-vscode-remote.vscode-remote-extensionpack
          ms-vscode.makefile-tools
          ms-vscode.powershell
          ms-vscode.remote-explorer
          ms-vscode.remote-server
          ms-vscode.vs-keybindings
          msjsdiag.vscode-react-native
          mutantdino.resourcemonitor
          onecentlin.laravel-blade
          pkief.material-icon-theme
          postman.postman-for-vscode
          prisma.prisma
          pwabuilder.pwa-studio
          redhat.vscode-yaml
          rocketseat.theme-omni
          rogalmic.bash-debug
          sanderronde.phpstan-vscode
          sandipchitale.vscode-kubernetes-helm-extras
          shakram02.bash-beautify
          sibiraj-s.vscode-scss-formatter
          sleistner.vscode-fileutils
          streetsidesoftware.code-spell-checker
          streetsidesoftware.code-spell-checker-british-english
          streetsidesoftware.code-spell-checker-dutch
          sumneko.lua
          syler.sass-indented
          tamasfe.even-better-toml
          tim-koehler.helm-intellisense
          tomoki1207.pdf
          typespec.typespec-vscode
          vscodevim.vim
          whizkydee.material-palenight-theme
          williamdasilva.lottie-viewer
          wix.vscode-import-cost
          xabikos.javascriptsnippets
          xdebug.php-debug
          yoavbls.pretty-ts-errors
          yzhang.markdown-all-in-one
          zhuangtongfa.material-theme
          zobo.php-intellisense
        ])
        ++ [ vscode-marketplace-release."42crunch".vscode-openapi ];
      userSettings = {
        # Theme & UI
        "workbench.colorTheme" = "Tokyo Night Storm";
        "workbench.iconTheme" = "material-icon-theme";
        "window.titleBarStyle" = "auto";
        "workbench.sideBar.location" = "right";
        "editor.minimap.enabled" = false;
        "workbench.editor.customLabels.patterns" = {
          "**/index.ts" = "\${dirname}";
          "**/index.tsx" = "\${dirname}";
          "**/index.js" = "\${dirname}";
          "**/index.jsx" = "\${dirname}";
        };

        # Editor
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'Fira Code', monospace";
        "editor.fontLigatures" = true;
        "editor.tabSize" = 2;
        "editor.formatOnSave" = true;
        "editor.formatOnPaste" = true;
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.smoothScrolling" = true;
        "editor.letterSpacing" = 1.2;
        "editor.inlineSuggest.enabled" = true;

        # Formatters
        "[javascript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[typescript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[typescriptreact]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[javascriptreact]"."editor.defaultFormatter" = "vscode.typescript-language-features";
        "[html]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[scss]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[json]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[jsonc]"."editor.defaultFormatter" = "vscode.json-language-features";
        "[vue]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[markdown]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[css]"."editor.defaultFormatter" = "vscode.css-language-features";
        "[php]"."editor.defaultFormatter" = "bmewburn.vscode-intelephense-client";
        "[prisma]"."editor.defaultFormatter" = "Prisma.prisma";

        # TypeScript / JavaScript
        "typescript.preferences.importModuleSpecifier" = "relative";
        "javascript.updateImportsOnFileMove.enabled" = "always";
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "typescript.disableAutomaticTypeAcquisition" = true;

        # Python
        "python.formatting.provider" = "black";
        "python.defaultInterpreterPath" = "/usr/bin/python3";

        # Git
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;
        "git.autofetch" = true;
        "git.enableCommitSigning" = true;

        # Terminal
        "terminal.integrated.profiles.osx" = {
          "zsh (nix)" = {
            "path" = "/etc/profiles/per-user/jonas/bin/zsh";
          };
        };
        "terminal.integrated.defaultProfile.osx" = "zsh (nix)";
        "terminal.integrated.profiles.linux" = {
          "zsh (login)" = {
            "path" = "/usr/bin/zsh";
            "args" = [ "-l" ];
          };
          "bash" = {
            "path" = "/bin/bash";
          };
          "zsh" = {
            "path" = "/usr/bin/zsh";
          };
        };
        "terminal.integrated.defaultProfile.linux" = "zsh (login)";
        "terminal.integrated.shellIntegration.decorationsEnabled" = "never";
        "terminal.integrated.ignoredShells" = [
          "starship"
          "oh-my-posh"
          "bash"
        ];
        "terminal.integrated.enableMultiLinePasteWarning" = "never";

        # Remote SSH
        "remote.SSH.remotePlatform" = {
          "192.168.0.239" = "linux";
        };

        # Docker
        "docker.images.label" = "RepositoryName";
        "docker.images.groupBy" = "Registry";
        "docker.containers.groupBy" = "Registry";
        "docker.languageserver.compose.enabled" = false;

        # Copilot
        "github.copilot.enable" = {
          "*" = true;
          "yaml" = false;
          "markdown" = false;
        };
        "github.copilot.editor.enableAutoCompletions" = true;
        "github.copilot.nextEditSuggestions.enabled" = true;

        # npm
        "npm.packageManager" = "pnpm";

        # Live Server
        "liveServer.settings.port" = 3000;

        # Telemetry opt-out
        "redhat.telemetry.enabled" = false;
        "snyk.yesTelemetry" = false;

        # Spell checker
        "cSpell.import" = [ ];
        "cSpell.userWords" = [
          "heroicon"
          "Infolist"
          "Infolists"
          "Machinecenter"
          "Mesco"
          "profunctional"
          "toggleable"
        ];

        # Tailwind
        "tailwindCSS.experimental.classRegex" = [
          [
            "cva\\(([^)]*)\\)"
            "[\"'`]([^\"'`]*).*?[\"'`]"
          ]
          [
            "cx\\(([^)]*)\\)"
            "(?:'|\"|`)([^']*)(?:'|\"|`)"
          ]
          [
            "twJoin\\(([^)]*)\\)"
            "(?:'|\"|`)([^']*)(?:'|\"|`)"
          ]
          [
            "twMerge\\(([^)]*)\\)"
            "(?:'|\"|`)([^']*)(?:'|\"|`)"
          ]
          [
            "cn\\(([^)]*)\\)"
            "(?:'|\"|`)([^']*)(?:'|\"|`)"
          ]
        ];

        # GitHub PRs
        "githubPullRequests.createOnPublishBranch" = "never";
        "githubPullRequests.pullBranch" = "never";

        # Claude Code
        "claude.position" = "panel";

        # Chat
        "chat.commandCenter.enabled" = false;
        "github.copilot.chat.codeGeneration.instructions" = [
          { "file" = ".github/instructions"; }
          { "file" = ".claude/rules"; }
          { "file" = "~/.copilot/instructions"; }
          { "file" = "~/.claude/rules"; }
        ];
        "chat.instructionsFilesLocations" = {
          ".github/instructions" = true;
          ".claude/rules" = true;
          "~/.copilot/instructions" = true;
          "~/.claude/rules" = true;
        };

        # Explorer
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;

        # Extensions from nix store don't have marketplace signatures
        "extensions.verifySignature" = false;

        # Misc
        "workbench.startupEditor" = "none";
        "workbench.editor.restoreViewState" = false;
        "window.newWindowProfile" = "Default";
      };

      keybindings = [
        {
          key = "ctrl+tab";
          command = "workbench.action.nextEditorInGroup";
        }
        {
          key = "ctrl+shift+tab";
          command = "workbench.action.previousEditorInGroup";
        }
        {
          key = "ctrl+space";
          command = "editor.action.triggerSuggest";
          when = "editorTextFocus";
        }
      ];
    };
  };

  home.activation.makeVscodeSettingsMutable =
    let
      settingsDir =
        if pkgs.stdenv.isDarwin then
          "$HOME/Library/Application Support/Code/User"
        else
          "$HOME/.config/Code/User";
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${settingsDir}/settings.json"
      if [ -L "$settings" ]; then
        target=$(readlink "$settings")
        run rm "$settings"
        run cp "$target" "$settings"
        run chmod u+w "$settings"
      fi
    '';
}
