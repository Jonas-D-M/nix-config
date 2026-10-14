local wezterm = require "wezterm"
local act = wezterm.action

local function scheme_for_appearance(appearance)
  return appearance:find("Dark") and "Tokyo Night Storm" or "Tokyo Night Day"
end

local config = wezterm.config_builder()

config.font = wezterm.font {
  family = "JetBrainsMono Nerd Font",
  weight = "Medium",
}
config.font_size = 14.0
config.line_height = 1.0

config.window_padding = {
  left   = "0.5cell",
  right  = "0.5cell",
  top    = "0.5cell",
  bottom = "0.5cell",
}
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- The config is re-evaluated when the OS appearance changes.
config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.7 }

config.default_cursor_style = "SteadyBlock"
-- Composed Option keys are needed for AZERTY symbols (@, #, |, ...).
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true

config.scrollback_lines = 50000
-- Updates come from Homebrew (macOS) or Nix (Linux).
config.check_for_updates = false

-- Extra quick-select (Ctrl+Shift+Space) targets; the defaults already cover
-- URLs, paths, hashes, UUIDs and IPs.
config.quick_select_patterns = {
  "\\b[a-z0-9-]+-[a-z0-9]{8,10}-[a-z0-9]{5}\\b", -- k8s Deployment pod names
}

config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- owner/repo#123 -> GitHub issue/PR
table.insert(config.hyperlink_rules, {
  regex = [[\b([\w.-]+)/([\w.-]+)#(\d+)\b]],
  format = "https://github.com/$1/$2/issues/$3",
})

config.keys = {
  { key = "w", mods = "CMD", action = act.CloseCurrentTab { confirm = false } },

  -- Clear screen and scrollback, like Terminal.app/iTerm
  {
    key = "k",
    mods = "CMD",
    action = act.Multiple {
      act.ClearScrollback "ScrollbackAndViewport",
      act.SendKey { key = "L", mods = "CTRL" },
    },
  },

  -- Panes (iTerm-style)
  { key = "d",     mods = "CMD",       action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "d",     mods = "CMD|SHIFT", action = act.SplitVertical { domain = "CurrentPaneDomain" } },
  { key = "Enter", mods = "CMD|SHIFT", action = act.TogglePaneZoomState },
  { key = "w",     mods = "CMD|SHIFT", action = act.CloseCurrentPane { confirm = false } },
  { key = "LeftArrow",  mods = "CMD|OPT", action = act.ActivatePaneDirection "Left" },
  { key = "RightArrow", mods = "CMD|OPT", action = act.ActivatePaneDirection "Right" },
  { key = "UpArrow",    mods = "CMD|OPT", action = act.ActivatePaneDirection "Up" },
  { key = "DownArrow",  mods = "CMD|OPT", action = act.ActivatePaneDirection "Down" },

  -- Jump between prompts (needs shell integration)
  { key = "UpArrow",   mods = "CMD|SHIFT", action = act.ScrollToPrompt(-1) },
  { key = "DownArrow", mods = "CMD|SHIFT", action = act.ScrollToPrompt(1) },
}

config.mouse_bindings = {
  -- Triple-click selects a whole command output (needs shell integration)
  {
    event = { Down = { streak = 3, button = "Left" } },
    mods = "NONE",
    action = act.SelectTextAtMouseCursor "SemanticZone",
  },
}

return config
