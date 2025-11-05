{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.custom.graphical.aerospace;
in
{
  options.custom.graphical.aerospace = {
    enable = lib.mkOption {
      default = false;
      example = true;
    };
  };

  config = mkIf cfg.enable {
    services.aerospace = {
      enable = false;
      settings = {
        mode.main.binding = {
          cmd-enter = "exec-and-forget open -n -a /Applications/WezTerm.app";
          cmd-b = "exec-and-forget open -n -a '/Applications/Google Chrome.app'";

          # Close window (Windows = Alt+F4). We provide both:
          alt-f4 = "close --quit-if-last-window";

          # Focus with Win+Arrows
          cmd-left = "focus left";
          cmd-down = "focus down";
          cmd-up = "focus up";
          cmd-right = "focus right";

          # Move window with Win+Shift+Arrows (like Windows snapping/move between zones)
          cmd-shift-left = "move left";
          cmd-shift-down = "move down";
          cmd-shift-up = "move up";
          cmd-shift-right = "move right";

          # Join containers (advanced tiling), Win+Ctrl+Arrows
          cmd-ctrl-left = "join-with left";
          cmd-ctrl-right = "join-with right";
          cmd-ctrl-up = "join-with up";
          cmd-ctrl-down = "join-with down";

          # Resize (keep it simple)
          cmd-minus = "resize smart -50";
          cmd-equal = "resize smart +50";

          # Monitor focus (Win+, / Win+.)
          cmd-comma = "focus-monitor left";
          cmd-period = "focus-monitor right";

          # Workspaces on F-keys to dodge AZERTY number-row:
          cmd-f1 = "workspace 1";
          cmd-f2 = "workspace 2";
          cmd-f3 = "workspace 3";
          cmd-f4 = "workspace 4";
          cmd-f5 = "workspace 5";
          cmd-f6 = "workspace 6";
          cmd-f7 = "workspace 7";
          cmd-f8 = "workspace 8";
          cmd-f9 = "workspace 9";
          cmd-f10 = "workspace 0";

          # Move window to workspace (Shift like Windows’ Win+Shift+Num)
          cmd-shift-f1 = "move-node-to-workspace 1";
          cmd-shift-f2 = "move-node-to-workspace 2";
          cmd-shift-f3 = "move-node-to-workspace 3";
          cmd-shift-f4 = "move-node-to-workspace 4";
          cmd-shift-f5 = "move-node-to-workspace 5";
          cmd-shift-f6 = "move-node-to-workspace 6";
          cmd-shift-f7 = "move-node-to-workspace 7";
          cmd-shift-f8 = "move-node-to-workspace 8";
          cmd-shift-f9 = "move-node-to-workspace 9";
          cmd-shift-f10 = "move-node-to-workspace 0";
        };

        # Keep your workspace-to-monitor assignment
        workspace-to-monitor-force-assignment = {
          "1" = "main";
          "2" = "main";
          "3" = "main";
          "4" = "main";
          "5" = "main";
          "6" = "secondary";
          "7" = "secondary";
          "8" = "secondary";
          "9" = "secondary";
          "0" = "secondary";
        };
      };
    };
  };
}
