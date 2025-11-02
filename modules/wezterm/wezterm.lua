local wezterm = require "wezterm"
local config = wezterm.config_builder()
local action = wezterm.action

config.font = wezterm.font {
  family = 'JetBrains Mono',
  weight = 'Medium',
  harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }, -- disable ligatures
}
config.font_size = 12.0
config.line_height = 1.0
config.window_padding = { left = '0.5cell', right = '0.5cell', top = '0.5cell', bottom = '0.5cell' }
config.default_cursor_style = 'SteadyBlock'

return config
