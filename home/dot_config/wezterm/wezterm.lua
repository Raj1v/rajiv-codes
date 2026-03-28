local wezterm = require("wezterm")

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
	enable_tab_bar = false,
	window_decorations = "RESIZE",
	color_scheme = scheme_for_appearance(wezterm.gui.get_appearance()),
	window_close_confirmation = "NeverPrompt",
	window_padding = {
		left = 8,
		right = 8,
		top = 0,
		bottom = 0,
	},
	keys = {
		{
			key = "w",
			mods = "CMD",
			action = wezterm.action.CloseCurrentTab({ confirm = false }),
		},
	},
}
