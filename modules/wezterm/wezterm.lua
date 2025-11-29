local wezterm = require "wezterm"

local function scheme_for_appearance(appearance)
  return appearance:find("Dark") and "Tokyo Night Storm" or "Tokyo Night Day"
end

local appearance = wezterm.gui.get_appearance()

local config     = {
  font                                        = wezterm.font {
    family = "JetBrains Mono",
    weight = "Medium",
  },

  font_size                                   = 14.0,
  line_height                                 = 1.0,

  window_padding                              = {
    left   = "0.5cell",
    right  = "0.5cell",
    top    = "0.5cell",
    bottom = "0.5cell",
  },
  window_decorations                          = "INTEGRATED_BUTTONS|RESIZE",

  default_cursor_style                        = "SteadyBlock",
  send_composed_key_when_left_alt_is_pressed  = true,
  send_composed_key_when_right_alt_is_pressed = true,

  color_scheme                                = scheme_for_appearance(appearance),
}

return config
