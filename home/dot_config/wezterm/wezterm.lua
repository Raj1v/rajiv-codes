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
		-- CMD+W → tmux kill window (prefix + X)
		{
			key = "w",
			mods = "CMD",
			action = wezterm.action.Multiple({
				wezterm.action.SendKey({ key = "f", mods = "CTRL" }),
				wezterm.action.SendKey({ key = "X", mods = "SHIFT" }),
			}),
		},
		-- OPT+W → tmux kill pane (prefix + x)
		{
			key = "w",
			mods = "ALT",
			action = wezterm.action.Multiple({
				wezterm.action.SendKey({ key = "f", mods = "CTRL" }),
				wezterm.action.SendKey({ key = "x" }),
			}),
		},
		-- CMD+F → tmux prefix (Ctrl+F)
		{ key = "f", mods = "CMD", action = wezterm.action.SendKey({ key = "f", mods = "CTRL" }) },
		-- CMD+[/] → prev/next tmux window (prefix + p / prefix + n)
		{ key = "[", mods = "CMD", action = wezterm.action.Multiple({ wezterm.action.SendKey({ key = "f", mods = "CTRL" }), wezterm.action.SendKey({ key = "p" }) }) },
		{ key = "]", mods = "CMD", action = wezterm.action.Multiple({ wezterm.action.SendKey({ key = "f", mods = "CTRL" }), wezterm.action.SendKey({ key = "n" }) }) },
		-- CMD+SHIFT+[/] → prev/next wezterm tab
		{ key = "[", mods = "CMD|SHIFT", action = wezterm.action.ActivateTabRelative(-1) },
		{ key = "]", mods = "CMD|SHIFT", action = wezterm.action.ActivateTabRelative(1) },
		-- OPT+[/] → cycle tmux panes (mapped to Alt+p/n in tmux.conf)
		{ key = "[", mods = "ALT", action = wezterm.action.SendKey({ key = "p", mods = "ALT" }) },
		{ key = "]", mods = "ALT", action = wezterm.action.SendKey({ key = "n", mods = "ALT" }) },
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
		-- CMD+T → new tmux window (prefix + c)
		{
			key = "t",
			mods = "CMD",
			action = wezterm.action.Multiple({
				wezterm.action.SendKey({ key = "f", mods = "CTRL" }),
				wezterm.action.SendKey({ key = "c" }),
			}),
		},
		-- CMD+SHIFT+T → new wezterm tab
		{ key = "t", mods = "CMD|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
		-- CMD+SHIFT+W → close wezterm tab
		{ key = "w", mods = "CMD|SHIFT", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
		-- CMD+N → new named tmux session (prefix + N)
		{
			key = "n",
			mods = "CMD",
			action = wezterm.action.Multiple({
				wezterm.action.SendKey({ key = "f", mods = "CTRL" }),
				wezterm.action.SendKey({ key = "N", mods = "SHIFT" }),
			}),
		},
		-- CMD+SHIFT+N → new wezterm window
		{ key = "n", mods = "CMD|SHIFT", action = wezterm.action.SpawnWindow },
		-- CMD+M → tmux zoom pane (prefix + z)
		{
			key = "m",
			mods = "CMD",
			action = wezterm.action.Multiple({
				wezterm.action.SendKey({ key = "f", mods = "CTRL" }),
				wezterm.action.SendKey({ key = "z" }),
			}),
		},
		-- CMD+1..9 → switch tmux window by number (prefix + digit). Overrides wezterm tab nav.
		{ key = "1", mods = "CMD", action = wezterm.action.Multiple({ wezterm.action.SendKey({ key = "f", mods = "CTRL" }), wezterm.action.SendKey({ key = "1" }) }) },
		{ key = "2", mods = "CMD", action = wezterm.action.Multiple({ wezterm.action.SendKey({ key = "f", mods = "CTRL" }), wezterm.action.SendKey({ key = "2" }) }) },
		{ key = "3", mods = "CMD", action = wezterm.action.Multiple({ wezterm.action.SendKey({ key = "f", mods = "CTRL" }), wezterm.action.SendKey({ key = "3" }) }) },
		{ key = "4", mods = "CMD", action = wezterm.action.Multiple({ wezterm.action.SendKey({ key = "f", mods = "CTRL" }), wezterm.action.SendKey({ key = "4" }) }) },
		{ key = "5", mods = "CMD", action = wezterm.action.Multiple({ wezterm.action.SendKey({ key = "f", mods = "CTRL" }), wezterm.action.SendKey({ key = "5" }) }) },
		{ key = "6", mods = "CMD", action = wezterm.action.Multiple({ wezterm.action.SendKey({ key = "f", mods = "CTRL" }), wezterm.action.SendKey({ key = "6" }) }) },
		{ key = "7", mods = "CMD", action = wezterm.action.Multiple({ wezterm.action.SendKey({ key = "f", mods = "CTRL" }), wezterm.action.SendKey({ key = "7" }) }) },
		{ key = "8", mods = "CMD", action = wezterm.action.Multiple({ wezterm.action.SendKey({ key = "f", mods = "CTRL" }), wezterm.action.SendKey({ key = "8" }) }) },
		{ key = "9", mods = "CMD", action = wezterm.action.Multiple({ wezterm.action.SendKey({ key = "f", mods = "CTRL" }), wezterm.action.SendKey({ key = "9" }) }) },
		-- ALT+S → send raw ESC+s (not macOS ß) for sesh zsh widget
		{ key = "s", mods = "ALT", action = wezterm.action.SendKey({ key = "s", mods = "ALT" }) },
		-- ALT+1..9 → send raw Meta+digit (not macOS ¡™£¢∞§¶•ª) for tmux pane select
		{ key = "1", mods = "ALT", action = wezterm.action.SendKey({ key = "1", mods = "ALT" }) },
		{ key = "2", mods = "ALT", action = wezterm.action.SendKey({ key = "2", mods = "ALT" }) },
		{ key = "3", mods = "ALT", action = wezterm.action.SendKey({ key = "3", mods = "ALT" }) },
		{ key = "4", mods = "ALT", action = wezterm.action.SendKey({ key = "4", mods = "ALT" }) },
		{ key = "5", mods = "ALT", action = wezterm.action.SendKey({ key = "5", mods = "ALT" }) },
		{ key = "6", mods = "ALT", action = wezterm.action.SendKey({ key = "6", mods = "ALT" }) },
		{ key = "7", mods = "ALT", action = wezterm.action.SendKey({ key = "7", mods = "ALT" }) },
		{ key = "8", mods = "ALT", action = wezterm.action.SendKey({ key = "8", mods = "ALT" }) },
		{ key = "9", mods = "ALT", action = wezterm.action.SendKey({ key = "9", mods = "ALT" }) },
	},
}
