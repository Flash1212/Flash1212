-- These are the basic's for using wezterm.
-- Mux is the mutliplexes for windows etc inside of the terminal
-- Action is to perform actions on the terminal
local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action

-- These are vars to put things in later (i dont use em all yet)
local background_image = ""
local config = {}
local default_shell = {}
local home = (os.getenv("HOME") or os.getenv("USERPROFILE"))
local keys = {}
local launch_menu = {}
local meta = "CTRL"
local mouse_bindings = {}
-- Use this variable to set all your keybindings in one place and then concat
-- them together at the end to set it to the config
local wez_keys = {}

-- Functions ---
function get_os()
	local is_darwin = wezterm.target_triple:find("darwin") ~= nil
	local is_linux = wezterm.target_triple:find("linux") ~= nil
	local is_windows = wezterm.target_triple:find("windows") ~= nil

	if is_windows then
		wezterm.log_info("Detected Windows OS")
		return "Windows"
	elseif is_linux then
		wezterm.log_info("Detected Linux OS")
		return "Linux"
	elseif is_darwin then
		wezterm.log_info("Detected Mac OS")
		return "Mac"
	else
		return "Unknown OS"
	end
end

function file_exists(path)
	local success = wezterm.glob(path)
	return #success > 0
end

-- Key binding helper function
function flatten_tables(table_of_tables)
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

local operating_system = get_os()

if operating_system == "Windows" then
	background_image = home .. "\\Pictures\\Saved pictures\\grayscale.png"
	meta = "CTRL"
	wezterm.log_info("Running on Windows")
	-- Set default shell to base powershell 7
	default_shell = { "pwsh.exe", "-NoLogo" }
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
			wezterm.log_info(
				"PowerShell not found at: " .. powershell_path .. " - using fallback: " .. default_shell[1]
			)
		end
	end
elseif operating_system == "Linux" then
	default_shell = { "/bin/zsh", "--login" }
	background_image = home .. "/Pictures/term/grayscale.png"
	meta = "CTRL"
	local msg = "Running on Linux\n"
	msg = msg .. "Default shell: " .. default_shell[1] .. "\n"
	msg = msg .. "Background Image: " .. background_image .. "\n"
	msg = msg .. "Meta Key: " .. meta
	wezterm.log_info(msg)
elseif operating_system == "Mac" then
	default_shell = { "zsh", "--login" }
	background_image = home .. "/Pictures/grayscale.png"
	meta = "CMD"
	wezterm.log_info("Running on Mac")
else
	wezterm.log_info("Running on an unknown OS")
end

-- Move by word with CTRL + Arrow keys
local mods_key = (operating_system == "Mac" or operating_system == "Linux") and "ALT" or "CTRL"
wez_keys["move_by_word"] = {
	{ key = "LeftArrow", mods = meta, action = act({ SendKey = { key = "b", mods = mods_key } }) },
	{ key = "RightArrow", mods = meta, action = act({ SendKey = { key = "f", mods = mods_key } }) },
}

-- CTRL-SHIFT-l activates the debug overlay
wez_keys["overlay"] = { key = "L", mods = meta, action = wezterm.action.ShowDebugOverlay }

-- Use ctr+c to copy and ctrl+v to paste the system clipboard
wez_keys["paste"] = { key = "v", mods = meta, action = act.PasteFrom("Clipboard") }
wez_keys["copy"] = {
	key = "c",
	mods = meta,
	action = wezterm.action_callback(function(window, pane)
		-- Check if there is any text selected
		local sel = window:get_selection_text_for_pane(pane)
		if sel and sel ~= "" then
			-- Copy to clipboard and primary selection
			window:perform_action(wezterm.action({ CopyTo = "ClipboardAndPrimarySelection" }), pane)
		else
			-- Send Ctrl+C to the terminal (SIGINT)
			window:perform_action(wezterm.action.SendKey({ key = "c", mods = "CTRL" }), pane)
		end
	end),
}

-- Increase and decrease font size with ctrl + and ctrl -
wez_keys["font_size"] = {
	{ key = "=", mods = meta, action = act.IncreaseFontSize },
	{ key = "-", mods = meta, action = act.DecreaseFontSize },
	{ key = "0", mods = meta, action = act.ResetFontSize },
}

-- Searching in the terminal, you can use ctrl+f to open the search bar. ctrl+U will clear the search bar
wez_keys["search"] = { key = "f", mods = meta, action = act.Search("CurrentSelectionOrEmptyString") }

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
-- Set the default shell when opening wezterm to PowerShell
config.default_prog = default_shell
-- Setup additional shells Profiles
if operating_system == "Windows" then
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
end
-- IMPORTANT: Sets WSL2 UBUNTU-22.04 as the defualt when opening Wezterm
-- config.default_domain = "WSL:Ubuntu-22.04"
wezterm.log_info("Finishing configuring WezTerm")
return config
