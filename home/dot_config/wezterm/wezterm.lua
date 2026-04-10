local wezterm = require("wezterm")

-- Open URLs sent from remote machines via OSC 1337 SetUserVar=openurl=<url>
wezterm.on("user-var-changed", function(window, pane, name, value)
	if name == "openurl" then
		wezterm.run_child_process({ "open", value })
	end
end)

-- Tab title: show (machine) process — machine is "local" or the SSH hostname.
-- Remote process name comes from the wezprocess user var set by the zshrc hook.
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
	initial_cols = 120,
	initial_rows = 36,
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
	-- Intercept CMD+click locally instead of forwarding to tmux (fixes link clicking with mouse mode on)
	bypass_mouse_reporting_modifiers = "SUPER",
	mouse_bindings = {
		{
			-- CompleteSelectionOrOpenLinkAtMouseCursor handles the case where a tiny
			-- drag selection started — it finishes the selection and still opens the link.
			event = { Up = { streak = 1, button = "Left" } },
			mods = "SUPER",
			action = wezterm.action.Multiple({
				wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor("ClipboardAndPrimarySelection"),
			}),
		},
	},
	keys = {
		{ key = "w", mods = "CMD", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
		-- CMD+F → tmux prefix (Ctrl+F)
		{ key = "f", mods = "CMD", action = wezterm.action.SendKey({ key = "f", mods = "CTRL" }) },
		-- CMD+[/] → cycle tmux panes (mapped to Alt+p/n in tmux.conf)
		{ key = "[", mods = "CMD", action = wezterm.action.SendKey({ key = "p", mods = "ALT" }) },
		{ key = "]", mods = "CMD", action = wezterm.action.SendKey({ key = "n", mods = "ALT" }) },
		-- CMD+HJKL / CMD+Arrows → vim-style tmux pane switching (mapped to Alt+hjkl in tmux.conf)
		{ key = "h", mods = "CMD", action = wezterm.action.SendKey({ key = "h", mods = "ALT" }) },
		{ key = "j", mods = "CMD", action = wezterm.action.SendKey({ key = "j", mods = "ALT" }) },
		{ key = "k", mods = "CMD", action = wezterm.action.SendKey({ key = "k", mods = "ALT" }) },
		{ key = "l", mods = "CMD", action = wezterm.action.SendKey({ key = "l", mods = "ALT" }) },
		{ key = "LeftArrow", mods = "CMD", action = wezterm.action.SendKey({ key = "h", mods = "ALT" }) },
		{ key = "DownArrow", mods = "CMD", action = wezterm.action.SendKey({ key = "j", mods = "ALT" }) },
		{ key = "UpArrow", mods = "CMD", action = wezterm.action.SendKey({ key = "k", mods = "ALT" }) },
		{ key = "RightArrow", mods = "CMD", action = wezterm.action.SendKey({ key = "l", mods = "ALT" }) },
		-- CMD+P → tmux prefix (Ctrl+F) then Shift+K (sesh connect)
		{
			key = "p",
			mods = "CMD",
			action = wezterm.action.Multiple({
				wezterm.action.SendKey({ key = "f", mods = "CTRL" }),
				wezterm.action.SendKey({ key = "K", mods = "SHIFT" }),
			}),
		},
		-- CMD+SHIFT+T → new tmux window (prefix + c)
		{
			key = "t",
			mods = "CMD|SHIFT",
			action = wezterm.action.Multiple({
				wezterm.action.SendKey({ key = "f", mods = "CTRL" }),
				wezterm.action.SendKey({ key = "c" }),
			}),
		},
		-- CMD+N → new named tmux session (prefix + N)
		{
			key = "n",
			mods = "CMD",
			action = wezterm.action.Multiple({
				wezterm.action.SendKey({ key = "f", mods = "CTRL" }),
				wezterm.action.SendKey({ key = "N", mods = "SHIFT" }),
			}),
		},
		-- CMD+M → tmux zoom pane (prefix + z)
		{
			key = "m",
			mods = "CMD",
			action = wezterm.action.Multiple({
				wezterm.action.SendKey({ key = "f", mods = "CTRL" }),
				wezterm.action.SendKey({ key = "z" }),
			}),
		},
		-- ALT+S → send raw ESC+s (not macOS ß) for sesh zsh widget
		{ key = "s", mods = "ALT", action = wezterm.action.SendKey({ key = "s", mods = "ALT" }) },
	},
}
