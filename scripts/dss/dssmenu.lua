local mod = BetterMonsters
local json = require("json")
local DSSMenu = {}

IRFConfig = {
	general    = {},
	enemies    = {},
	bosses     = {},
	minibosses = {},
	champions  = {},
	secrets    = {},
}

-- Default DSS Data
IRFDefaultConfig = {
	general = {
		breakableHosts   = true,
		spawnIndicators  = true,
		burrowIndicators = true,
		laserIndicators  = true,
		coinSteal 		 = true,
	},

	enemies = {
		angelicBaby 	  = true,
		blackBony 		  = true,
		blackGlobin 	  = true,
		blister 		  = true,
		boneKnight 		  = true,
		codWorm 		  = true,
		dankDeathHead 	  = true,
		dankGlobin 		  = true,
		dartFly 		  = true,
		drownedBoomFly    = true,
		drownedCharger    = true,
		drownedHive       = true,
		classicEternalFly = true,
		fatBat 			  = true,
		flamingFatty 	  = true,
		flamingGaper 	  = true,
		burningGushers    = true,
		flamingHopper 	  = true,
		fleshDeathHead    = true,
		lump 			  = true,
		mamaGuts 		  = true,
		megaClotty 		  = true,
		membrain 		  = true,
		momsDeadHand 	  = true,
		nerveEndingTwo    = true,
		nest 			  = true,
		noChapter1Nests   = true,
		slide 			  = true,
		portal 			  = true,
		psyTumor 		  = true,
		raglings 		  = true,
		redMaw 			  = true,
		scarredGuts 	  = true,
		scarredParabite   = true,
		selflessKnight    = true,
		skinnies 		  = true,
		taintedFaceless   = true,
		ulcer 			  = true,
	},

	bosses = {
		blastocyst    = true,
		blightedOvum  = true,
		blueBaby 	  = true,
		carrionQueen  = true,
		chad 		  = true,
		conquest 	  = true,
		daddyLongLegs = true,
		forsaken 	  = true,
		gate 		  = true,
		gish 		  = true,
		bossGurglings = true,
		hushBaby 	  = true,
		husk 		  = true,
		itLives 	  = true,
		lokii 		  = true,
		mamaGurdy 	  = true,
		maskInfamy    = true,
		megaMaw 	  = true,
		mrFred 		  = true,
		ragMega 	  = true,
		satan 		  = true,
		scolex 		  = true,
		stain 		  = true,
		steven 		  = true,
		teratoma 	  = true,
	},

	minibosses = {
		envy 		  = true,
		superGluttony = true,
		superGreed    = true,
		lust 		  = true,
		superPride    = true,
		sloth 		  = true,
		wrath 		  = true,
		fallenAngels  = true,
	},

	champions = {
		bloat 		= true,
		cage 		= true,
		death 		= true,
		frail 		= true,
		greenGemini = true,
		blueGemini  = true,
		gurdy 		= true,
		haunt 		= true,
		lilHaunts 	= true,
		larryJr 	= true,
		lilHorn 	= true,
		megaMaw 	= true,
		monstro 	= true,
		peep 		= true,
	},

	secrets = {
		found 	 = false,
		babyMode = false,
	},
}
local secretButtonAdded = false



-- Load settings
function DSSMenu:LoadSaveData()
    if mod:HasData() then
		IRFConfig = json.decode(mod:LoadData())
    end

    for k, v in pairs(IRFDefaultConfig) do
		-- Convert old save system to the new one
		if type(IRFConfig[k]) ~= "table" then
			IRFConfig[k] = v
		end

		for i, j in pairs(v) do
			if IRFConfig[k][i] == nil then
				IRFConfig[k][i] = j
			end
		end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, DSSMenu.LoadSaveData)

-- Save settings
function DSSMenu:SaveData()
	mod:SaveData(json.encode(IRFConfig))
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, DSSMenu.SaveData)



-- Menu START!!!

-- boring variables
local DSSModName = "Dead Sea Scrolls (Reworked Foes)"
local DSSCoreVersion = 7
local MenuProvider = {}

-- why why why why why whyyyyyy
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



-- Changelog BS
include("scripts.dss.changelog")

local changeLogButton = dssmod.changelogsButton
if changeLogButton ~= false then
	changeLogButton = { str = 'changelogs', action = 'openmenu', menu = 'Menu', dest = 'changelogs' }
end


-- Settings helpers
local wikiTooltip = { strset = { 'check the wiki', 'linked on the', 'workshop for', 'more details' }}

local function CreateSetting(settingName, displayName, displayTooltip)
	-- Get the proper setting variable
	local splitSetting = mod:SplitString(settingName, '.')
	local settingGroup = splitSetting[1]
	local settingIndex = splitSetting[2]

	-- Create the setting entry
	local setting = {
		str = displayName,
		fsize = 2,
		choices = {'on', 'off'},
		setting = 1,
		variable = settingName,

		load = function()
			if IRFConfig[settingGroup][settingIndex] ~= nil then
				if IRFConfig[settingGroup][settingIndex] then
					return 1
				else
					return 2
				end
			end
			return 1
		end,

		store = function(var)
			local bool = false
			if var == 1 then
				bool = true
			end
			IRFConfig[settingGroup][settingIndex] = bool
		end
	}

	-- Add tooltip if it has one
	if displayTooltip then
		setting.tooltip = { strset = displayTooltip }
	end

	return setting
end



-- Adding a Menu
local exampledirectory = {
	-- Main menu
    main = {
        title = 'reworked foes',
        buttons = {
			{ str = 'resume game', action = 'resume' },
			{ str = 'settings',    dest = 'settings' },
			changeLogButton,
			{ str = 'credits',     dest = 'credits' },
			-- Secret menu button
        },
        tooltip = dssmod.menuOpenToolTip
    },


	-- Settings menu
    settings = {
        title = 'settings',
        buttons = {
			{ str = '', fsize = 2, nosel = true },
			{ str = 'general',    dest = 'general' },
			{ str = 'enemies',    dest = 'enemies' },
			{ str = 'bosses', 	  dest = 'bosses' },
			{ str = 'minibosses', dest = 'minibosses' },
			{ str = 'champions',  dest = 'champions' },

			{ str = '', fsize = 3, nosel = true },
			{ str = 'reset settings', fsize = 2, dest = 'resetSettings' },

			-- DSS settings
			{ str = '', fsize = 3, nosel = true },
			dssmod.gamepadToggleButton,
            dssmod.menuKeybindButton,
            dssmod.paletteButton,
            dssmod.menuHintButton,
            dssmod.menuBuzzerButton,
        }
    },


	-- General settings
	general = {
        title = 'general settings',
        buttons = {
			CreateSetting("general.breakableHosts", "breakable hosts", { "hosts' armor", 'can be broken', 'by a bomb', 'or high damage' }),
			CreateSetting("general.spawnIndicators", "spawn indicators", { 'play an', 'animation when', "mom's hands,", 'needles, pin', 'and similar', 'enemies spawn' }),
			CreateSetting("general.burrowIndicators", "hiding indicators", { 'show an', 'indicator when', 'pin, dust,', 'polycephalus', 'and similar', 'enemies are', 'hidden' }),
			CreateSetting("general.laserIndicators", "laser indicators", { 'show an', 'indicator', 'where some', "enemies'", 'lasers are', 'about to be', 'fired' }),
			CreateSetting("general.coinSteal", "extra greedy enemies", { "greed and", 'other greedy', 'enemies can', 'steal coins', 'and heal', 'from them', '(outside of', 'greed mode)' }),
        },
        tooltip = dssmod.menuOpenToolTip
    },


	-- Enemy settings
	enemies = {
        title = 'enemy settings',
        buttons = {
			CreateSetting("enemies.angelicBaby", "angelic baby rework"),
			CreateSetting("enemies.blackBony", "black bony rework"),
			CreateSetting("enemies.blackGlobin", "black globin rework"),
			CreateSetting("enemies.blister", "blister rework"),
			CreateSetting("enemies.boneKnight", "bone knight changes"),
			CreateSetting("enemies.codWorm", "cod worm rework"),
			CreateSetting("enemies.dankDeathHead", "dank death head rework"),
			CreateSetting("enemies.dankGlobin", "dank globin rework"),
			CreateSetting("enemies.dartFly", "dart fly rework"),
			CreateSetting("enemies.drownedBoomFly", "drown. boomfly rework"),
			CreateSetting("enemies.drownedCharger", "drown. charger rework"),
			CreateSetting("enemies.drownedHive", "better drowned hive"),
			CreateSetting("enemies.classicEternalFly", "classic eternal flies"),
			CreateSetting("enemies.fatBat", "fat bat changes"),
			CreateSetting("enemies.flamingFatty", "flaming fatty rework"),
			CreateSetting("enemies.flamingGaper", "flaming gaper rework"),
			CreateSetting("enemies.burningGushers", "burning gushers"),
			CreateSetting("enemies.flamingHopper", "flaming hopper rework"),
			CreateSetting("enemies.fleshDeathHead", "flesh d. head rework"),
			CreateSetting("enemies.lump", "lump rework"),
			CreateSetting("enemies.mamaGuts", "harder mama guts"),
			CreateSetting("enemies.megaClotty", "mega clotty rework"),
			CreateSetting("enemies.membrain", "membrain rework"),
			CreateSetting("enemies.momsDeadHand", "mom's dead hand rework"),
			CreateSetting("enemies.nerveEndingTwo", "nerve ending 2 rework"),
			CreateSetting("enemies.nest", "nest changes"),
			CreateSetting("enemies.noChapter1Nests", "replace nests in ch. 1"),
			CreateSetting("enemies.slide", "slide rework"),
			CreateSetting("enemies.portal", "portal rework"),
			CreateSetting("enemies.psyTumor", "psy tumor rework"),
			CreateSetting("enemies.raglings", "harder raglings"),
			CreateSetting("enemies.redMaw", "red maw rework"), -- get rid of this rework it sucks
			CreateSetting("enemies.scarredGuts", "harder scarred guts"),
			CreateSetting("enemies.scarredParabite", "scar. para-bite rework"),
			CreateSetting("enemies.selflessKnight", "selfless knight rework"),
			CreateSetting("enemies.skinnies", "skinny + rotty rework"),
			CreateSetting("enemies.taintedFaceless", "harder tainted faceless"),
			CreateSetting("enemies.ulcer", "ulcer rework"),
        },
        tooltip = wikiTooltip
    },


	-- Boss settings
	bosses = {
        title = 'boss settings',
        buttons = {
			CreateSetting("bosses.blastocyst", "harder big blastocyst"),
			CreateSetting("bosses.blightedOvum", "blighted ovum rework"),
			CreateSetting("bosses.blueBaby", "??? rework"),
			CreateSetting("bosses.carrionQueen", "carrion queen changes"),
			CreateSetting("bosses.chad", "c.h.a.d. rework"),
			CreateSetting("bosses.conquest", "conquest 2nd phase"),
			CreateSetting("bosses.daddyLongLegs", "better daddy long legs"),
			CreateSetting("bosses.forsaken", "forsaken rework"),
			CreateSetting("bosses.gate", "gate rework"),
			CreateSetting("bosses.gish", "gish rework"),
			CreateSetting("bosses.bossGurglings", "boss gurgling sprites"),
			CreateSetting("bosses.hushBaby", "hush blue baby rework"),
			CreateSetting("bosses.husk", "husk rework"),
			CreateSetting("bosses.itLives", "it lives rework"),
			CreateSetting("bosses.lokii", "lokii rework"),
			CreateSetting("bosses.mamaGurdy", "mama gurdy rework"),
			CreateSetting("bosses.maskInfamy", "mask of infamy rework"),
			CreateSetting("bosses.megaMaw", "harder mega maw"),
			CreateSetting("bosses.mrFred", "mr. fred rework"),
			CreateSetting("bosses.ragMega", "rag mega rework"),
			CreateSetting("bosses.satan", "harder satan"),
			CreateSetting("bosses.scolex", "scolex rework"),
			CreateSetting("bosses.stain", "harder stain"),
			CreateSetting("bosses.steven", "steven rework"),
			CreateSetting("bosses.teratoma", "better teratoma"),
        },
        tooltip = wikiTooltip
    },


	-- Miniboss settings
	minibosses = {
        title = 'miniboss settings',
        buttons = {
			CreateSetting("minibosses.envy", "envy rework"),
			CreateSetting("minibosses.superGluttony", "harder super gluttony"),
			CreateSetting("minibosses.superGreed", "super greed pickup steal"),
			CreateSetting("minibosses.lust", "lust rework"),
			CreateSetting("minibosses.superPride", "harder super pride"),
			CreateSetting("minibosses.sloth", "better sloth"),
			CreateSetting("minibosses.wrath", "harder wrath"),
			CreateSetting("minibosses.fallenAngels", "harder fallen angels"),
        },
        tooltip = wikiTooltip
    },


	-- Champion settings
	champions = {
        title = 'champion settings',
        buttons = {
			CreateSetting("champions.bloat", "better green bloat"),
			CreateSetting("champions.cage", "green cage rework"),
			CreateSetting("champions.death", "no black death red maws"),
			CreateSetting("champions.frail", "black frail rework"),
			CreateSetting("champions.greenGemini", "green gemini creep"),
			CreateSetting("champions.blueGemini", "blue gemini creep"),
			CreateSetting("champions.gurdy", "new green gurdy spawns"),
			CreateSetting("champions.haunt", "better black haunt"),
			CreateSetting("champions.lilHaunts", "matching lil haunts"),
			CreateSetting("champions.larryJr", "blue larry jr. creep"),
			CreateSetting("champions.lilHorn", "harder black lil horn"),
			CreateSetting("champions.megaMaw", "harder black mega maw"),
			CreateSetting("champions.monstro", "harder gray monstro"),
			CreateSetting("champions.peep", "blue peep rework"),
        },
        tooltip = wikiTooltip
    },


	-- Reset settings
	resetSettings = {
        title = 'reset settings',
        buttons = {
			{ str = "are you sure?", nosel = true },
			{ str = "", nosel = true },

			{ str = "cancel", action = "back" },
			{ str = "", fsize = 2, nosel = true },

			{ str = "i'm sure!", action = "back",
				func = function(button, item, root)
					local wasSecretFound = IRFConfig.secrets.found

					IRFConfig = IRFDefaultConfig
					IRFConfig.secrets.found = wasSecretFound

					DSSMenu:SaveData()
					DSSMenu:LoadSaveData()

					dssmod.reloadButtons(root, root.Directory.settings.general)
					dssmod.reloadButtons(root, root.Directory.settings.enemies)
					dssmod.reloadButtons(root, root.Directory.settings.bosses)
					dssmod.reloadButtons(root, root.Directory.settings.minibosses)
					dssmod.reloadButtons(root, root.Directory.settings.champions)
					dssmod.reloadButtons(root, root.Directory.settings.secrets)
				end
			},
        },
        tooltip = { strset = { 'this cannot', 'be undone'}}
    },


	-- Credits
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
			{ str = 'menu implementation', fsize = 2, nosel = true },
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

			{ str = 'shh...', fsize = 3, dest = "secrets",
			func = function()
				IRFConfig.secrets.found = true
				DSSMenu:AddSecretButton()
			end
			},
        },
        tooltip = dssmod.menuOpenToolTip
    },


	-- Secret menu
	secrets = {
        title = "it's a secret...",
        buttons = {
			CreateSetting("secrets.babyMode", "easy mode", { 'can i play,', 'daddy?' }),
			CreateSetting("secrets.found", "placeholder"),
        },
        tooltip = dssmod.menuOpenToolTip
    },
}



-- Add secret menu button
function DSSMenu:AddSecretButton()
	if secretButtonAdded == false and IRFConfig.secrets.found == true then
		table.insert(exampledirectory.main.buttons, { str = 'secrets', dest = 'secrets', glowcolor = 3 })
		secretButtonAdded = true
	end
end
mod:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, CallbackPriority.LATE, DSSMenu.AddSecretButton)



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