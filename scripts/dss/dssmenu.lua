local mod = BetterMonsters
local json = require("json")
local DSSMenu = {}

IRFConfig = {}

--Default DSS Data
IRFDefaultConfig = {
	--General
	breakableHosts   = true,
	noChapter1Nests  = true,
	matriarchFistula = true,
	envyRework 		 = true,
	blackBonyBombs   = true,
	burningGushers   = true,

	--Hidden enemy visuals
	noHiddenPins  = true,
	noHiddenPoly  = true,
	noHiddenDust  = true,
	
	--Extra appear animations
	appearPins 		= true,
	appearMomsHands = true,
	appearNeedles 	= true,
	
	--Laser indicators
	laserEyes 	  = true,
	laserRedGhost = true,
}

--Load settings
function DSSMenu:LoadSaveData()
    if mod:HasData() then
        local data = json.decode(mod:LoadData())
        for k, v in pairs(data) do
            if IRFConfig[k] ~= nil then IRFConfig[k] = v end
        end
    end

    return IRFConfig
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, DSSMenu.LoadSaveData)

--Get settings
function DSSMenu:GetData()
    if not IRFConfig then
        IRFConfig = IRFDefaultConfig
    end

    return IRFConfig
end

--Save settings
function DSSMenu:SaveData()
	mod:SaveData(json.encode(IRFConfig))
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, DSSMenu.SaveData)

--Menu START!!!

--boring variables
local DSSModName = "Dead Sea Scrolls (Reworked Foes)"
local DSSCoreVersion = 7
local MenuProvider = {}

--why why why why why whyyyyyy
function MenuProvider.SaveSaveData()
    DSSMenu.SaveData()
end
function MenuProvider.GetPaletteSetting()
    return IRFConfig.PaletteSetting
end
function MenuProvider.SavePaletteSetting(var)
    IRFConfig.PaletteSetting = var
end
function MenuProvider.GetHudOffsetSetting()
    if not REPENTANCE then
        return IRFConfig.HudOffset
    else
        return Options.HUDOffset * 10
    end
end
function MenuProvider.SaveHudOffsetSetting(var)
    if not REPENTANCE then
        IRFConfig.HudOffset = var
    end
end
function MenuProvider.GetGamepadToggleSetting()
    return IRFConfig.GamepadToggle
end
function MenuProvider.SaveGamepadToggleSetting(var)
    IRFConfig.GamepadToggle = var
end
function MenuProvider.GetMenuKeybindSetting()
    return IRFConfig.MenuKeybind
end
function MenuProvider.SaveMenuKeybindSetting(var)
    IRFConfig.MenuKeybind = var
end
function MenuProvider.GetMenuHintSetting()
    return IRFConfig.MenuHint
end
function MenuProvider.SaveMenuHintSetting(var)
    IRFConfig.MenuHint = var
end
function MenuProvider.GetMenuBuzzerSetting()
    return IRFConfig.MenuBuzzer
end
function MenuProvider.SaveMenuBuzzerSetting(var)
    IRFConfig.MenuBuzzer = var
end
function MenuProvider.GetMenusNotified()
    return IRFConfig.MenusNotified
end
function MenuProvider.SaveMenusNotified(var)
    IRFConfig.MenusNotified = var
end
function MenuProvider.GetMenusPoppedUp()
    return IRFConfig.MenusPoppedUp
end
function MenuProvider.SaveMenusPoppedUp(var)
    IRFConfig.MenusPoppedUp = var
end

local DSSInitializerFunction = require("scripts.dss.dssmenucore")
local dssmod = DSSInitializerFunction(DSSModName, DSSCoreVersion, MenuProvider)

-- Adding a Menu
local exampledirectory = {
    main = {
        title = 'reworked foes',
        buttons = {
            { str = 'resume game', action = 'resume' },
            { str = 'settings',    dest = 'settings' },
            dssmod.changelogsButton,
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
                variable = 'breakableHosts',
                load = function()
                    if IRFConfig.breakableHosts ~= nil then
                        if IRFConfig.breakableHosts then
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
                        IRFConfig.breakableHosts = true
                    else
                        IRFConfig.breakableHosts = false
                    end
                end,
                tooltip = { strset = { 'host armor', 'can be broken', 'by a bomb', 'or high damage' } }
            },
            {
                str = 'no basement nests',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'noChapter1Nests',
                load = function()
                    if IRFConfig.noChapter1Nests ~= nil then
                        if IRFConfig.noChapter1Nests then
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
                        IRFConfig.noChapter1Nests = true
                    else
                        IRFConfig.noChapter1Nests = false
                    end
                end,
                tooltip = { strset = { 'replace nests', 'in chapter 1', 'with easier', 'mullicocoons' } }
            },
            {
                str = 'matriarch fistula',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'matriarchFistula',
                load = function()
                    if IRFConfig.matriarchFistula ~= nil then
                        if IRFConfig.matriarchFistula then
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
                        IRFConfig.matriarchFistula = true
                    else
                        IRFConfig.matriarchFistula = false
                    end
                end,
                tooltip = { strset = { 'fistula chunks', 'spawned by', 'matriarch will', 'have better', 'colors' } }
            },
            {
                str = 'envy rework',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'envyRework',
                load = function()
                    if IRFConfig.envyRework ~= nil then
                        if IRFConfig.envyRework then
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
                        IRFConfig.envyRework = true
                    else
                        IRFConfig.envyRework = false
                    end
                end,
                tooltip = { strset = { 'envy heads', 'will bounce', 'off of each', 'other' } }
            },
            {
                str = 'black bony bombs',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'blackBonyBombs',
                load = function()
                    if IRFConfig.blackBonyBombs ~= nil then
                        if IRFConfig.blackBonyBombs then
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
                        IRFConfig.blackBonyBombs = true
                    else
                        IRFConfig.blackBonyBombs = false
                    end
                end,
                tooltip = { strset = { 'black bonies', 'will spawn', 'with random', 'bomb effects' } }
            },
            {
                str = 'burning gushers',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'burningGushers',
                load = function()
                    if IRFConfig.burningGushers ~= nil then
                        if IRFConfig.burningGushers then
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
                        IRFConfig.burningGushers = true
                    else
                        IRFConfig.burningGushers = false
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
                variable = 'pin',
                load = function()
                    if IRFConfig.noHiddenPins ~= nil then
                        if IRFConfig.noHiddenPins then
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
                        IRFConfig.noHiddenPins = true
                    else
                        IRFConfig.noHiddenPins = false
                    end
                end,
                tooltip = { strset = { 'show indicator', 'when pin and', 'similar bosses', 'are hidden'} }
            },
            {                
                str = 'polycephalus',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'polycephalus',
                load = function()
                    if IRFConfig.noHiddenPoly ~= nil then
                        if IRFConfig.noHiddenPoly then
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
                        IRFConfig.noHiddenPoly = true
                    else
                        IRFConfig.noHiddenPoly = false
                    end
                end,
                tooltip = { strset = { 'show', 'indicator when', 'polycephalus', 'and similar', 'bosses are', 'hidden' } }
            },
            {                
                str = 'dust',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'dust',
                load = function()
                    if IRFConfig.noHiddenDust ~= nil then
                        if IRFConfig.noHiddenDust then
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
                        IRFConfig.noHiddenDust = true
                    else
                        IRFConfig.noHiddenDust = false
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
                variable = 'pintwo',
                load = function()
                    if IRFConfig.appearPins ~= nil then
                        if IRFConfig.appearPins then
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
                        IRFConfig.appearPins = true
                    else
                        IRFConfig.appearPins = false
                    end
                end,
                tooltip = { strset = { 'play animation', 'when pin and', 'similar bosses', 'spawn'} }
            },
            {                
                str = 'needles',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'needles',
                load = function()
                    if IRFConfig.appearNeedles ~= nil then
                        if IRFConfig.appearNeedles then
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
                        IRFConfig.appearNeedles = true
                    else
                        IRFConfig.appearNeedles = false
                    end
                end,
                tooltip = { strset = { 'play animation', 'when needles', 'and similar' , 'enemies spawn' } }
            },
            {                
                str = 'moms hand',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'momshand',
                load = function()
                    if IRFConfig.appearMomsHands ~= nil then
                        if IRFConfig.appearMomsHands then
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
                        IRFConfig.appearMomsHands = true
                    else
                        IRFConfig.appearMomsHands = false
                    end
                end,
                tooltip = { strset = {  'play', 'animation when', 'moms hand', 'and similar' , 'enemies spawn' } }
            },
            { str = '', fsize = 3, nosel = true },
            { str = 'laser indicators', fsize = 3, nosel = true },
            { str = '', fsize = 3, nosel = true },
            {                
                str = 'laser eyes',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'eyes',
                load = function()
                    if IRFConfig.laserEyes ~= nil then
                        if IRFConfig.laserEyes then
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
                        IRFConfig.laserEyes = true
                    else
                        IRFConfig.laserEyes = false
                    end
                end,
                tooltip = { strset = { 'show', 'indicator when', 'laser eyes', 'fire lasers'} }
            },
            {                
                str = 'red ghosts',
                choices = {'true', 'false'},
                setting = 1,
                variable = 'ghosts',
                load = function()
                    if IRFConfig.laserRedGhost ~= nil then
                        if IRFConfig.laserRedGhost then
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
                        IRFConfig.laserRedGhost = true
                    else
                        IRFConfig.laserRedGhost = false
                    end
                end,
                tooltip = { strset = { 'show', 'indicator when', 'red ghosts', 'fire lasers' } }
            },
            dssmod.gamepadToggleButton,
            dssmod.menuKeybindButton,
            dssmod.paletteButton,
            dssmod.menuHintButton,
            dssmod.menuBuzzerButton,
        }
    }
}

local exampledirectorykey = {
    -- This is the initial item of the menu, generally you want to set it to your main item
    Item = exampledirectory.main,
    -- The main item of the menu is the item that gets opened first when opening your mod's menu.
    Main = 'main',
    -- These are default state variables for the menu; they're important to have in here, but you
    -- don't need to change them at all.
    Idle = false,
    MaskAlpha = 1,
    Settings = {},
    SettingsChanged = false,
    Path = {},
}

DeadSeaScrollsMenu.AddMenu("reworked foes", {
    -- The Run, Close, and Open functions define the core loop of your menu. Once your menu is
    -- opened, all the work is shifted off to your mod running these functions, so each mod can have
    -- its own independently functioning menu. The `init` function returns a table with defaults
    -- defined for each function, as "runMenu", "openMenu", and "closeMenu". Using these defaults
    -- will get you the same menu you see in Bertran and most other mods that use DSS. But, if you
    -- did want a completely custom menu, this would be the way to do it!

    -- This function runs every render frame while your menu is open, it handles everything!
    -- Drawing, inputs, etc.
    Run = dssmod.runMenu,
    -- This function runs when the menu is opened, and generally initializes the menu.
    Open = dssmod.openMenu,
    -- This function runs when the menu is closed, and generally handles storing of save data /
    -- general shut down.
    Close = dssmod.closeMenu,
    -- If UseSubMenu is set to true, when other mods with UseSubMenu set to false / nil are enabled,
    -- your menu will be hidden behind an "Other Mods" button.
    -- A good idea to use to help keep menus clean if you don't expect players to use your menu very
    -- often!
    UseSubMenu = false,
    Directory = exampledirectory,
    DirectoryKey = exampledirectorykey
})

-- There are a lot more features that DSS supports not covered here, like sprite insertion and
-- scroller menus, that you'll have to look at other mods for reference to use. But, this should be
-- everything you need to create a simple menu for configuration or other simple use cases!