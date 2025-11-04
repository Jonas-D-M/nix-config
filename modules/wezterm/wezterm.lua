local wezterm                                      = require "wezterm"
local config                                       = wezterm.config_builder()
local action                                       = wezterm.action

config.font                                        = wezterm.font {
  family = 'JetBrains Mono',
  weight = 'Medium',
  -- harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }, -- disable ligatures
}
config.font_size                                   = 14.0
config.line_height                                 = 1.0
config.window_padding                              = {
  left = '0.5cell',
  right = '0.5cell',
  top = '0.5cell',
  bottom =
  '0.5cell'
}
config.default_cursor_style                        = 'SteadyBlock'
config.send_composed_key_when_left_alt_is_pressed  = true
config.send_composed_key_when_right_alt_is_pressed = true

return config
