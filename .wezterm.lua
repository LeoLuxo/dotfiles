-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux
local nf = wezterm.nerdfonts


-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end




config.win32_system_backdrop = 'Acrylic'
config.window_background_opacity = 0.3
config.window_decorations = "RESIZE"
config.window_padding = {
	left = 25,
	right = 25,
	top = 2,
	bottom = 15,
}
config.window_close_confirmation = 'NeverPrompt'

-- config.default_cursor_style = 'BlinkingBar' -- Doesn't work for some reason

config.color_scheme = 'OneHalfDark'
config.font_size = 14.0
config.font = wezterm.font 'Mononoki Nerd Font'

config.prefer_to_spawn_tabs = true







local default_domain = { name = "?", icon = nf.cod_terminal, color = "white" }

local domains = {
	["local"] = { name = "nu", icon = nf.fa_windows, color = "#7dc4e4", shortcut = "1" },
	["WSL:Ubuntu"] = { name = "WSL", icon = nf.cod_terminal_ubuntu, color = "#f5a97f", shortcut = "2" },
}

local function basename(path)
	return path and path:match("([^/\\]+)[/\\]?$") or ""
end



-- Tab Bar
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.status_update_interval = 500
config.tab_max_width = 25
config.tab_bar_at_bottom = false

config.colors = {
	tab_bar = {
		background = '#333333',
	}
}

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local domain_info = domains[tab.active_pane.domain_name] or default_domain
	local cwd = basename(tab.active_pane.current_working_dir.path)

	local max = max_width - 5 - wezterm.column_width(domain_info.name)

	if wezterm.column_width(cwd) > max then
		cwd = wezterm.truncate_right(cwd, max - 1) .. '…'
	end

	local edge_background = '#333333'
	local background = '#181818'
	local foreground = '#808080'

	if tab.is_active then
		background = '#282828'
		foreground = '#d0d0d0'
		shell_intensity = 'Bold'
	elseif hover then
		background = '#383838'
		foreground = '#909090'
	end

	local title = wezterm.format({
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = background } },
		{ Text = nf.ple_left_half_circle_thick },
		{ Background = { Color = background } },
		{ Foreground = { Color = domain_info.color } },
		{ Text = domain_info.icon },
		{ Text = " " },
		{ Attribute = { Intensity = tab.is_active and 'Bold' or 'Normal' } },
		{ Text = domain_info.name },
		{ Attribute = { Intensity = 'Normal' } },
		{ Text = " " },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Attribute = { Underline = tab.is_active and 'Single' or 'None' } },
		{ Text = cwd },
		{ Attribute = { Underline = 'None' } },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = background } },
		{ Text = nf.ple_right_half_circle_thick },
	})

	return title
end)

wezterm.on("update-status", function(window, pane)
	local process = basename(pane:get_foreground_process_name())
	local time = wezterm.strftime("%H:%M:%S")
	local hostname = " " .. wezterm.hostname() .. " ";

	local workspace_or_leader = nil

	if window:active_key_table() then
		workspace_or_leader = window:active_key_table()
	elseif window:leader_is_active() then
		workspace_or_leader = "LEADER"
	end

	workspace_or_leader = workspace_or_leader and (nf.oct_table .. " " .. workspace_or_leader .. " | ") or ""

	window:set_right_status(wezterm.format({
		{ Text = workspace_or_leader },
		{ Foreground = { Color = "FFB86C" } },
		{ Text = nf.fa_code .. " " .. process },
		"ResetAttributes",
		{ Text = " | " },
		{ Text = nf.md_clock .. " " .. time .. " " },
	}))
end)

wezterm.on('gui-startup', function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)






-- Keyboard
config.enable_kitty_keyboard = true

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 3000 }

config.keys = {
	{ key = 'd', mods = "LEADER", action = act.SpawnCommandInNewTab { domain = 'CurrentPaneDomain', }, },
	{ key = 'v', mods = 'CTRL',   action = act.PasteFrom 'Clipboard' },
	{
		key = 'c',
		mods = 'CTRL',
		action = wezterm.action_callback(function(window, pane)
			selection_text = window:get_selection_text_for_pane(pane)
			is_selection_active = string.len(selection_text) ~= 0
			if is_selection_active then
				window:perform_action(act.CopyTo('ClipboardAndPrimarySelection'), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act.SendKey { key = 'c', mods = 'CTRL' }, pane)
			end
		end),
	},
}

-- Quick domain
for d, v in pairs(domains) do
	table.insert(config.keys, {
		key = v.shortcut,
		mods = "LEADER",
		action = act.SpawnCommandInNewTab {
			domain = { DomainName = d },
		},
	})
end



config.default_prog = { 'nu', '-e', 'startup-hook', '--env-config', '~/.nu/env.nu', '--config', '~/.nu/config.nu' }

-- and finally, return the configuration to wezterm
return config
