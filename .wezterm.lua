-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action


-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices
config.enable_kitty_keyboard = true
config.allow_win32_input_mode = false
config.keys = {
	-- { key = 'V', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },
	-- { key = 'C', mods = 'CTRL', action = act.CopyTo 'Clipboard' },
}

-- config.color_scheme = 'Catppuccin Mocha'
config.color_scheme = 'OneHalfDark'
config.win32_system_backdrop = 'Acrylic'
config.window_background_opacity = 0.3

config.font_size = 14.0
config.font = wezterm.font 'Mononoki Nerd Font'
-- config.font = wezterm.font_with_fallback {
-- 	'My Preferred Font',
-- 	-- This font has a broader selection of Chinese glyphs than my preferred font
-- 	'DengXian',
--  },
config.use_fancy_tab_bar = true
config.window_decorations = "RESIZE"
config.window_padding = {
	left = 25,
	right = 25,
	top = 2,
	bottom = 15,
}
config.window_frame = {
	-- The font used in the tab bar.
	-- Roboto Bold is the default; this font is bundled
	-- with wezterm.
	-- Whatever font is selected here, it will have the
	-- main font setting appended to it to pick up any
	-- fallback fonts you may have used there.
	font = wezterm.font { family = 'Roboto', weight = 'Bold' },

	-- The size of the font in the tab bar.
	-- Default to 10.0 on Windows but 12.0 on other systems
	font_size = 12.0,

	-- The overall background color of the tab bar when
	-- the window is focused
	active_titlebar_bg = '#333333',

	-- The overall background color of the tab bar when
	-- the window is not focused
	inactive_titlebar_bg = '#333333',
}

config.colors = {
	tab_bar = {
		-- The color of the inactive tab bar edge/divider
		inactive_tab_edge = '#575757',
	},
}


config.default_prog = { 'nu', '--env-config', '~/.nu/env.nu', '--config', '~/.nu/config.nu' }
-- config.default_prog = { 'C:\\Program Files\\Git\\bin\\bash.exe' }
-- and finally, return the configuration to wezterm
return config
