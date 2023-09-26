local mod = ReworkedFoes
local json = require("json")
local DSSMenu = {}

mod.Config = {}



--Default DSS Data
local defaultConfig = {
	--General
	BreakableHosts  = true,
    CoinStealing    = true,
	NoChapter1Nests = true,
	EnvyRework 		= true,
	BlackBonyBombs  = true,
	BurningGushers  = true,

	--Hidden enemy visuals
	NoHiddenPins = true,
	NoHiddenPoly = true,
	NoHiddenDust = true,

	--Extra appear animations
	AppearPins 		= true,
	AppearMomsHands = true,
	AppearNeedles 	= true,
}



--Load settings
function DSSMenu:LoadSaveData()
    if mod:HasData() then
		mod.Config = json.decode(mod:LoadData())
    end

    for k, v in pairs(defaultConfig) do
        if mod.Config[k] == nil then
            mod.Config[k] = v
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, DSSMenu.LoadSaveData)

--Save settings
function DSSMenu:SaveData()
	mod:SaveData(json.encode(mod.Config))
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, DSSMenu.SaveData)



-- Initialize Dead Sea Scrolls
--boring variables
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



-- Changelog
include("rf_scripts.dss.changelog")

local changeLogButton = dssmod.changelogsButton
if changeLogButton == true then
	changeLogButton = { str = 'changelogs',  action = "openmenu", menu = 'Menu', dest = 'changelogs', }
end



-- Menus
local directory = {
    main = {
        title = 'reworked foes',
        buttons = {
            { str = 'resume game', action = 'resume' },
            { str = 'settings',    dest   = 'settings' },
			{ str = 'credits',     dest   = 'credits' },
            changeLogButton,
        },
        tooltip = dssmod.menuOpenToolTip
    },

    settings = {
        title = 'settings',
        buttons = {
            { str = 'general', fsize = 3, nosel = true },
            { str = '', fsize = 3, nosel = true },
            {
                str = 'breakable hosts',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'BreakableHosts',
                load = function()
                    if mod.Config.BreakableHosts ~= nil then
                        if mod.Config.BreakableHosts then
                            return 1
                        else
                            return 2
                        end
                    else
                        return 1
                    end
                end,
                store = function(var)
                    if var == 1 then
                        mod.Config.BreakableHosts = true
                    else
                        mod.Config.BreakableHosts = false
                    end
                end,
                tooltip = { strset = { 'host armor', 'can be broken', 'by a bomb', 'or high damage' } }
            },
            {
                str = 'coin stealing foes',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'CoinStealing',
                load = function()
                    if mod.Config.CoinStealing ~= nil then
                        if mod.Config.CoinStealing then
                            return 1
                        else
                            return 2
                        end
                    else
                        return 1
                    end
                end,
                store = function(var)
                    if var == 1 then
                        mod.Config.CoinStealing = true
                    else
                        mod.Config.CoinStealing = false
                    end
                end,
                tooltip = { strset = { 'greed themed', 'enemies', 'will steal', 'nearby coins' } }
            },
            {
                str = 'no basement nests',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'NoChapter1Nests',
                load = function()
                    if mod.Config.NoChapter1Nests ~= nil then
                        if mod.Config.NoChapter1Nests then
                            return 1
                        else
                            return 2
                        end
                    else
                        return 1
                    end
                end,
                store = function(var)
                    if var == 1 then
                        mod.Config.NoChapter1Nests = true
                    else
                        mod.Config.NoChapter1Nests = false
                    end
                end,
                tooltip = { strset = { 'replace nests', 'in chapter 1', 'with easier', 'mullicocoons' } }
            },
            {
                str = 'envy rework',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'EnvyRework',
                load = function()
                    if mod.Config.EnvyRework ~= nil then
                        if mod.Config.EnvyRework then
                            return 1
                        else
                            return 2
                        end
                    else
                        return 1
                    end
                end,
                store = function(var)
                    if var == 1 then
                        mod.Config.EnvyRework = true
                    else
                        mod.Config.EnvyRework = false
                    end
                end,
                tooltip = { strset = { 'envy heads', 'will bounce', 'off of each', 'other' } }
            },
            {
                str = 'black bony bombs',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'BlackBonyBombs',
                load = function()
                    if mod.Config.BlackBonyBombs ~= nil then
                        if mod.Config.BlackBonyBombs then
                            return 1
                        else
                            return 2
                        end
                    else
                        return 1
                    end
                end,
                store = function(var)
                    if var == 1 then
                        mod.Config.BlackBonyBombs = true
                    else
                        mod.Config.BlackBonyBombs = false
                    end
                end,
                tooltip = { strset = { 'black bonies', 'will spawn', 'with random', 'bomb effects' } }
            },
            {
                str = 'burning gushers',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'BurningGushers',
                load = function()
                    if mod.Config.BurningGushers ~= nil then
                        if mod.Config.BurningGushers then
                            return 1
                        else
                            return 2
                        end
                    else
                        return 1
                    end
                end,
                store = function(var)
                    if var == 1 then
                        mod.Config.BurningGushers = true
                    else
                        mod.Config.BurningGushers = false
                    end
                end,
                tooltip = { strset = { 'gushers', 'spawned by', 'flaming gapers', 'will have', 'new behaviour' } }
            },

            { str = '', fsize = 3, nosel = true },
            { str = 'enemy indicators', fsize = 3, nosel = true },
            { str = '', fsize = 3, nosel = true },

            {
                str = 'pin',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'NoHiddenPins',
                load = function()
                    if mod.Config.NoHiddenPins ~= nil then
                        if mod.Config.NoHiddenPins then
                            return 1
                        else
                            return 2
                        end
                    else
                        return 1
                    end
                end,
                store = function(var)
                    if var == 1 then
                        mod.Config.NoHiddenPins = true
                    else
                        mod.Config.NoHiddenPins = false
                    end
                end,
                tooltip = { strset = { 'show indicator', 'when pin and', 'similar bosses', 'are hidden'} }
            },
            {
                str = 'polycephalus',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'NoHiddenPoly',
                load = function()
                    if mod.Config.NoHiddenPoly ~= nil then
                        if mod.Config.NoHiddenPoly then
                            return 1
                        else
                            return 2
                        end
                    else
                        return 1
                    end
                end,
                store = function(var)
                    if var == 1 then
                        mod.Config.NoHiddenPoly = true
                    else
                        mod.Config.NoHiddenPoly = false
                    end
                end,
                tooltip = { strset = { 'show', 'indicator when', 'polycephalus', 'and similar', 'bosses are', 'hidden' } }
            },
            {
                str = 'dust',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'NoHiddenDust',
                load = function()
                    if mod.Config.NoHiddenDust ~= nil then
                        if mod.Config.NoHiddenDust then
                            return 1
                        else
                            return 2
                        end
                    else
                        return 1
                    end
                end,
                store = function(var)
                    if var == 1 then
                        mod.Config.NoHiddenDust = true
                    else
                        mod.Config.NoHiddenDust = false
                    end
                end,
                tooltip = { strset = { 'show indicator', 'when dust and', 'similar enemies',  'are hidden' } }
            },

            { str = '', fsize = 3, nosel = true },
            { str = 'spawn indicators', fsize = 3, nosel = true },
            { str = '', fsize = 3, nosel = true },

            {
                str = 'pin',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'AppearPins',
                load = function()
                    if mod.Config.AppearPins ~= nil then
                        if mod.Config.AppearPins then
                            return 1
                        else
                            return 2
                        end
                    else
                        return 1
                    end
                end,
                store = function(var)
                    if var == 1 then
                        mod.Config.AppearPins = true
                    else
                        mod.Config.AppearPins = false
                    end
                end,
                tooltip = { strset = { 'play animation', 'when pin and', 'similar bosses', 'spawn'} }
            },
            {
                str = 'needles',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'AppearNeedles',
                load = function()
                    if mod.Config.AppearNeedles ~= nil then
                        if mod.Config.AppearNeedles then
                            return 1
                        else
                            return 2
                        end
                    else
                        return 1
                    end
                end,
                store = function(var)
                    if var == 1 then
                        mod.Config.AppearNeedles = true
                    else
                        mod.Config.AppearNeedles = false
                    end
                end,
                tooltip = { strset = { 'play animation', 'when needles', 'and similar' , 'enemies spawn' } }
            },
            {
                str = 'moms hand',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'AppearMomsHands',
                load = function()
                    if mod.Config.AppearMomsHands ~= nil then
                        if mod.Config.AppearMomsHands then
                            return 1
                        else
                            return 2
                        end
                    else
                        return 1
                    end
                end,
                store = function(var)
                    if var == 1 then
                        mod.Config.AppearMomsHands = true
                    else
                        mod.Config.AppearMomsHands = false
                    end
                end,
                tooltip = { strset = {  'play', 'animation when', 'moms hand', 'and similar' , 'enemies spawn' } }
            },

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

			{ str = '- ratratrat -', fsize = 3 },
			{ str = 'dss menu implementation', fsize = 2, nosel = true },
			{ str = 'save system coder', fsize = 2, nosel = true },
			{ str = '', fsize = 3, nosel = true },

			{ str = '- kittenchilly -', fsize = 3 },
			{ str = 'classic eternal flies', fsize = 2, nosel = true },
			{ str = 'additional coding', fsize = 2, nosel = true },
			{ str = '', fsize = 3, nosel = true },

			{ str = '- nevernamed -', fsize = 3 },
			{ str = 'thumbnail artist', fsize = 2, nosel = true },
			{ str = '', fsize = 3, nosel = true },

			{ str = '- sinbiscuit -', fsize = 3 },
			{ str = 'compatibility help', fsize = 2, nosel = true },
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