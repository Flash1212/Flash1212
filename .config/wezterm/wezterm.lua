-- These are the basic's for using wezterm.
-- Mux is the mutliplexes for windows etc inside of the terminal
-- Action is to perform actions on the terminal
local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action

-- These are vars to put things in later (i dont use em all yet)
local config = {}
local keys = {}
local mouse_bindings = {}
local launch_menu = {}

function file_exists(path)
	local success = wezterm.glob(path)
	return #success > 0
end

-- Key binding helper function
local function flatten_tables(table_of_tables)
	local flattened = {}
	for _, key in pairs(table_of_tables) do
		if type(key) == "table" and key.key then
			table.insert(flattened, key)
		elseif type(key) == "table" then
			for _, subkey in ipairs(key) do
				table.insert(flattened, subkey)
			end
		end
	end
	return flattened
end

-- This is for newer wezterm versions to use the config builder
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Use this variable to set all your keybindings in one place and then concat
-- them together at the end to set it to the config
local wez_keys = {}

-- CTRL-SHIFT-l activates the debug overlay
wez_keys["overlay"] = { key = "L", mods = "CTRL", action = wezterm.action.ShowDebugOverlay }

-- Use ctrl+v to paste the system clipboard
wez_keys["paste"] = { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") }

-- Searching in the terminal, you can use ctrl+f to open the search bar.
wez_keys["search"] = { key = "f", mods = "CTRL", action = act.Search("CurrentSelectionOrEmptyString") }

-- Split panes in the terminal and navigating between them.
wez_keys["panes"] = {
	{ key = "H", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "V", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "LeftArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
}

-- These are mouse binding to mimc Windows Terminal and let you copy
-- To copy just highlight something and right click. Simple
mouse_bindings = {
	{
		event = { Down = { streak = 3, button = "Left" } },
		action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
		mods = "NONE",
	},
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
			end
		end),
	},
}

-- This is used to make my foreground (text, etc) brighter than my background
config.foreground_text_hsb = { hue = 1.0, saturation = 1.2, brightness = 1.5 }

-- This is used to set an image as my background
local background_image = "C:/Users/thorn/Pictures/Saved pictures/grayscale.png"
config.background = {
	{
		hsb = { brightness = 0.25 },
		opacity = 0.95,
		source = { File = { path = background_image, speed = 0.2 } },
		width = "100%",
	},
}

-- Color scheme, Wezterm has 100s of them you can see here:
-- https://wezfurlong.org/wezterm/colorschemes/index.html
config.colors = {
	scrollbar_thumb = "FF767474",
}
config.color_scheme = "Oceanic Next (Gogh)"
config.default_cursor_style = "BlinkingBar" -- makes my cursor blink
config.disable_default_key_bindings = true
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 11
config.keys = flatten_tables(wez_keys) -- Concat all keys together
config.launch_menu = launch_menu
config.mouse_bindings = mouse_bindings
config.enable_scroll_bar = true

-- Set default shell to base powershell 7
local default_shell = { "pwsh.exe", "-NoLogo" }

-- Attempt to get powershell from the WindowsApps directory if possible.
-- wezterm.log_info() can be seen in the debug overlay (CTRL-SHIFT-l)
local local_appdata = os.getenv("LOCALAPPDATA")
if local_appdata then
	wezterm.log_info("Checking for PowerShell in WindowsApps directory: " .. local_appdata)
	local powershell_path = local_appdata .. "\\Microsoft\\WindowsApps\\pwsh.exe"
	wezterm.log_info("Constructed PowerShell path: " .. powershell_path)
	local exists = file_exists(powershell_path)
	if exists then
		wezterm.log_info("Found PowerShell at: " .. powershell_path)
		default_shell = { powershell_path, "-NoLogo" }
	else
		wezterm.log_info("PowerShell not found at: " .. powershell_path .. " - using fallback: " .. default_shell[1])
	end
end

-- Set the default shell when opening wezterm to PowerShell
config.default_prog = default_shell
wezterm.log_info("Default shell set to: " .. default_shell[1])

-- Setup additional shells Profiles
config.launch_menu = {
	{
		label = "PowerShell",
		args = { "powershell.exe", "-NoLogo" },
	},
	{
		label = "PWSH",
		args = default_shell,
	},
}
-- IMPORTANT: Sets WSL2 UBUNTU-22.04 as the defualt when opening Wezterm
-- config.default_domain = "WSL:Ubuntu-22.04"
return config
