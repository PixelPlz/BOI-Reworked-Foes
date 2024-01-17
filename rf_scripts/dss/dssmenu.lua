local mod = ReworkedFoes
local json = require("json")
local DSSMenu = {}

mod.Config = {}



-- Default DSS Data
mod.DefaultConfig = {
	-- General
	BreakableHosts 		= true,
	CoinStealing 		= true,
	ChampionChanges 	= true,
	ClassicEternalFlies = true,
	NoChapter1Nests 	= true,
	EnvyRework 			= true,
	BlackBonyBombs 		= true,
	BurningGushers 		= true,

	-- Hidden enemy visuals
	NoHiddenPins = true,
	NoHiddenPoly = true,
	NoHiddenDust = true,

	-- Extra appear animations
	AppearPins 		= true,
	AppearMomsHands = true,
	AppearNeedles 	= true,
}



-- Load settings
function DSSMenu:LoadSaveData()
	if mod:HasData() then
		mod.Config = json.decode(mod:LoadData())
	end

	for k, v in pairs(mod.DefaultConfig) do
		if mod.Config[k] == nil then
			local keyString = tostring(k)
			local keyFirst = string.sub(keyString, 1, 1)
			local keyLast = string.sub(keyString, 2)
			local key = string.lower(keyFirst) .. keyLast

			-- Convert old variable
			if mod.Config[key] ~= nil then
				mod.Config[k] = mod.Config[key]

			-- No matching old variable found
			else
				mod.Config[k] = v
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, DSSMenu.LoadSaveData)

-- Save settings
function DSSMenu:SaveData()
	mod:SaveData(json.encode(mod.Config))
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, DSSMenu.SaveData)



-- Initialize Dead Sea Scrolls
-- Boring variables
local DSSModName = "Dead Sea Scrolls (Reworked Foes)"
local DSSCoreVersion = 7
local MenuProvider = {}

function MenuProvider.SaveSaveData()
	DSSMenu.SaveData()
end
function MenuProvider.GetPaletteSetting()
	return mod.Config.PaletteSetting
end
function MenuProvider.SavePaletteSetting(var)
	mod.Config.PaletteSetting = var
end
function MenuProvider.GetHudOffsetSetting()
	if not REPENTANCE then
		return mod.Config.HudOffset
	else
		return Options.HUDOffset * 10
	end
end
function MenuProvider.SaveHudOffsetSetting(var)
	if not REPENTANCE then
		mod.Config.HudOffset = var
	end
end
function MenuProvider.GetGamepadToggleSetting()
	return mod.Config.GamepadToggle
end
function MenuProvider.SaveGamepadToggleSetting(var)
	mod.Config.GamepadToggle = var
end
function MenuProvider.GetMenuKeybindSetting()
	return mod.Config.MenuKeybind
end
function MenuProvider.SaveMenuKeybindSetting(var)
	mod.Config.MenuKeybind = var
end
function MenuProvider.GetMenuHintSetting()
	return mod.Config.MenuHint
end
function MenuProvider.SaveMenuHintSetting(var)
	mod.Config.MenuHint = var
end
function MenuProvider.GetMenuBuzzerSetting()
	return mod.Config.MenuBuzzer
end
function MenuProvider.SaveMenuBuzzerSetting(var)
	mod.Config.MenuBuzzer = var
end
function MenuProvider.GetMenusNotified()
	return mod.Config.MenusNotified
end
function MenuProvider.SaveMenusNotified(var)
	mod.Config.MenusNotified = var
end
function MenuProvider.GetMenusPoppedUp()
	return mod.Config.MenusPoppedUp
end
function MenuProvider.SaveMenusPoppedUp(var)
	mod.Config.MenusPoppedUp = var
end

local DSSInitializerFunction = require("rf_scripts.dss.dssmenucore")
local dssmod = DSSInitializerFunction(DSSModName, DSSCoreVersion, MenuProvider)

include("rf_scripts.dss.changelog")



-- Settings helper
function mod:CreateDSSToggle(settingName, displayName, displayTooltip)
	-- Create the setting entry
	local setting = {
		str = displayName,
		fsize = 2,
		choices = {'on', 'off'},
		setting = 1,
		variable = settingName,

		load = function()
			if mod.Config[settingName] ~= nil then
				if mod.Config[settingName] then
					return 1
				else
					return 2
				end
			end
			return 1
		end,

		store = function(var)
			local bool = var == 1
			mod.Config[settingName] = bool
		end
	}

	-- Add tooltip if it has one
	if displayTooltip then
		setting.tooltip = { strset = displayTooltip }
	end

	return setting
end



-- Menus
local directory = {
	main = {
		title = 'reworked foes',
		buttons = {
			{ str = 'resume game', action = 'resume' },
			{ str = 'settings',    dest   = 'settings' },
			dssmod.changelogsButton,
			{ str = 'credits',     dest   = 'credits' },
		},
		tooltip = dssmod.menuOpenToolTip
	},

	settings = {
		title = 'settings',
		buttons = {
			{ str = 'general', fsize = 3, nosel = true },
			{ str = '', fsize = 1, nosel = true },

			mod:CreateDSSToggle("BreakableHosts",      "breakable hosts",         { 'host armor', 'can be broken', 'by a bomb', 'or high damage' }),
			mod:CreateDSSToggle("CoinStealing",        "coin stealing enemies",   { 'greed themed', 'enemies', 'will steal', 'nearby coins' }),
			mod:CreateDSSToggle("ChampionChanges",     "enemy champion changes",  { 'some enemy', 'champions', 'will have', 'different', 'drops or', 'behaviour' }),
			mod:CreateDSSToggle("ClassicEternalFlies", "classic eternal flies",   { 'eternal flies', 'will keep', 'their', 'appearance', 'when chasing', 'the player' }),
			mod:CreateDSSToggle("NoChapter1Nests",     "no chapter 1 nests",      { 'replace nests', 'in chapter 1', 'with easier', 'mullicocoons' }),
			mod:CreateDSSToggle("EnvyRework",          "envy rework",             { 'envy heads', 'will bounce', 'off of each', 'other' }),
			mod:CreateDSSToggle("BlackBonyBombs",      "black bony bomb effects", { 'black bonies', 'will spawn', 'with random', 'bomb effects' }),
			mod:CreateDSSToggle("BurningGushers",      "burning gushers",         { 'gushers', 'spawned by', 'flaming gapers', 'will have', 'new behaviour' }),

			{ str = '', fsize = 3, nosel = true },
			{ str = 'enemy indicators', fsize = 3, nosel = true },
			{ str = '', fsize = 1, nosel = true },

			mod:CreateDSSToggle("NoHiddenPins", "pin",          { 'show indicator', 'when pin and', 'similar bosses', 'are hidden' }),
			mod:CreateDSSToggle("NoHiddenPoly", "polycephalus", { 'show', 'indicator when', 'polycephalus', 'and similar', 'bosses are', 'hidden' }),
			mod:CreateDSSToggle("NoHiddenDust", "dust",         { 'show indicator', 'when dust and', 'similar enemies',  'are hidden' }),

			{ str = '', fsize = 3, nosel = true },
			{ str = 'spawn indicators', fsize = 3, nosel = true },
			{ str = '', fsize = 1, nosel = true },

			mod:CreateDSSToggle("AppearPins",      "pin",       { 'play animation', 'when pin and', 'similar bosses', 'spawn' }),
			mod:CreateDSSToggle("AppearNeedles",   "needles",   { 'play animation', 'when needles', 'and similar' , 'enemies spawn' }),
			mod:CreateDSSToggle("AppearMomsHands", "moms hand", { 'play', 'animation when', 'moms hand', 'and similar' , 'enemies spawn' }),

			{ str = '', fsize = 3, nosel = true },
			dssmod.gamepadToggleButton,
			dssmod.menuKeybindButton,
			dssmod.paletteButton,
			dssmod.menuHintButton,
			dssmod.menuBuzzerButton,
		}
	},

	credits = {
		title = 'credits',
		buttons = {
			{ str = '- pixelplz -', fsize = 3 },
			{ str = 'mod creator', fsize = 2, nosel = true },
			{ str = 'coder', fsize = 2, nosel = true },
			{ str = 'designer', fsize = 2, nosel = true },
			{ str = 'spriter', fsize = 2, nosel = true },
			{ str = '', fsize = 3, nosel = true },

			{ str = '- ferpe -', fsize = 3 },
			{ str = 'spriter', fsize = 2, nosel = true },
			{ str = 'animator', fsize = 2, nosel = true },
			{ str = '', fsize = 3, nosel = true },

			{ str = '- witchamy -', fsize = 3 },
			{ str = 'designer', fsize = 2, nosel = true },
			{ str = '', fsize = 3, nosel = true },

			{ str = '- kittenchilly -', fsize = 3 },
			{ str = 'beast tweaks', fsize = 2, nosel = true },
			{ str = 'enemy champion changes', fsize = 2, nosel = true },
			{ str = 'classic eternal flies', fsize = 2, nosel = true },
			{ str = '', fsize = 3, nosel = true },

			{ str = '- ratratrat -', fsize = 3 },
			{ str = 'dss menu implementation', fsize = 2, nosel = true },
			{ str = 'save system', fsize = 2, nosel = true },
			{ str = '', fsize = 3, nosel = true },

			{ str = '- sinbiscuit -', fsize = 3 },
			{ str = 'compatibility help', fsize = 2, nosel = true },
			{ str = '', fsize = 3, nosel = true },

			{ str = '- nevernamed -', fsize = 3 },
			{ str = 'thumbnail artist', fsize = 2, nosel = true },
			{ str = '', fsize = 3, nosel = true },

			{ str = '- deadinfinity -', fsize = 3 },
			{ str = 'beast tweaks', fsize = 2, nosel = true },
			{ str = '', fsize = 3, nosel = true },

			{ str = '- hgrfff -', fsize = 3 },
			{ str = 'hush fixes', fsize = 2, nosel = true },
			{ str = '', fsize = 3, nosel = true },
		},
		tooltip = dssmod.menuOpenToolTip
	},
}



-- Add the menu
local directorykey = {
	Item = directory.main,
	Main = 'main',
	Idle = false,
	MaskAlpha = 1,
	Settings = {},
	SettingsChanged = false,
	Path = {},
}

DeadSeaScrollsMenu.AddMenu("reworked foes", {
	Run = dssmod.runMenu,
	Open = dssmod.openMenu,
	Close = dssmod.closeMenu,
	UseSubMenu = false,
	Directory = directory,
	DirectoryKey = directorykey
})