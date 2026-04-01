local wezterm = require("wezterm")

-- Open URLs sent from remote machines via OSC 1337 SetUserVar=openurl=<url>
wezterm.on("user-var-changed", function(window, pane, name, value)
	if name == "openurl" then
		wezterm.run_child_process({ "open", value })
	end
end)

wezterm.on("format-tab-title", function(tab)
	local pane = tab.active_pane
	local process = pane.foreground_process_name:match("([^/]+)$") or ""
	local machine = "local"

	if process == "ssh" then
		local title = pane.title or ""
		machine = title:match("@([%w._-]+)") or title:match("^([%w._-]+)") or "remote"
		local uv = pane.user_vars or {}
		process = uv.wezprocess or "ssh"
	end

	return string.format(" (%s) %s ", machine, process)
end)


local function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Catppuccin Mocha"
	else
		return "Catppuccin Latte"
	end
end

return {
	font = wezterm.font_with_fallback({ "Hack Nerd Font", "Apple Color Emoji" }),
	font_size = 18.0,
	hide_tab_bar_if_only_one_tab = true,
	window_decorations = "RESIZE",
	color_scheme = scheme_for_appearance(wezterm.gui.get_appearance()),
	window_close_confirmation = "NeverPrompt",
	window_padding = {
		left = 8,
		right = 8,
		top = 0,
		bottom = 0,
	},
	mouse_bindings = {
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "SUPER",
			action = wezterm.action.OpenLinkAtMouseCursor,
		},
	},
	keys = {
		{
			key = "w",
			mods = "CMD",
			action = wezterm.action.CloseCurrentTab({ confirm = false }),
		},
		{
			key = "f",
			mods = "CMD",
			action = wezterm.action.SendKey({ key = "f", mods = "CTRL" }),
		},
		{
			key = "[",
			mods = "CMD",
			action = wezterm.action.SendKey({ key = "p", mods = "ALT" }),
		},
		{
			key = "]",
			mods = "CMD",
			action = wezterm.action.SendKey({ key = "n", mods = "ALT" }),
		},
	},
}
