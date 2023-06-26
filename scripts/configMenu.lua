local mod = BetterMonsters
local json = require("json")

-- THIS WHOLE FILE SHOULD BE GONE AFTER DSS IS IMPLEMENTED, MOVE IRFCONFIG TO DSS SCRIPT OR CONSTANTS --

IRFConfig = {
	-- General
	breakableHosts   = true,
	noChapter1Nests  = true,
	matriarchFistula = true,
	envyRework 		 = true,
	blackBonyBombs   = true,
	burningGushers   = true,

	-- Hidden enemy visuals
	noHiddenPins  = true,
	noHiddenPoly  = true,
	noHiddenDust  = true,
	
	-- Extra appear animations
	appearPins 		= true,
	appearMomsHands = true,
	appearNeedles 	= true,
	
	-- Laser indicators
	laserEyes 	  = true,
	laserRedGhost = true,
}



-- Load settings
function mod:postGameStarted()
    if mod:HasData() then
        local data = json.decode(mod:LoadData())
        for k, v in pairs(data) do
            if IRFConfig[k] ~= nil then IRFConfig[k] = v end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.postGameStarted)

-- Save settings
function mod:preGameExit()
	mod:SaveData(json.encode(IRFConfig))
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.preGameExit)



-- Menu options
if ModConfigMenu then
  	local category = "Reworked Foes"
	ModConfigMenu.RemoveCategory(category);
  	ModConfigMenu.UpdateCategory(category, {
		Name = category,
		Info = "Change settings for Improved & Reworked Foes"
	})


	-- General--
	-- Breakable hosts
	ModConfigMenu.AddSetting(category, "General", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.breakableHosts
		end,
	    Display = function()
			return "Breakable Hosts: " .. (IRFConfig.breakableHosts and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.breakableHosts = bool
	    end,
		Info = {"Host armor will break if they get bombed or take more than their max HP in damage at once."}
  	})
	-- Ch.1 Nests
	ModConfigMenu.AddSetting(category, "General", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.noChapter1Nests
		end,
	    Display = function()
			return "Replace Nests in Chapter 1: " .. (IRFConfig.noChapter1Nests and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.noChapter1Nests = bool
	    end,
	    Info = {"Nests in the first two floors will be replaced by easier Mullicocoons."}
  	})
	-- Matriarch Fistulas
	ModConfigMenu.AddSetting(category, "General", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.matriarchFistula
		end,
	    Display = function()
			return "Matriarch Fistulas: " .. (IRFConfig.matriarchFistula and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.matriarchFistula = bool
	    end,
	    Info = {"Better colors for Fistulas spawned by the Matriarch."}
  	})
	-- Envy bounces
	ModConfigMenu.AddSetting(category, "General", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.envyRework
		end,
	    Display = function()
			return "Envy rework: " .. (IRFConfig.envyRework and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.envyRework = bool
	    end,
	    Info = {"Envy's heads will bounce off of each other."}
  	})
	-- Black Bony bombs
	ModConfigMenu.AddSetting(category, "General", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.blackBonyBombs
		end,
	    Display = function()
			return "Black Bony bomb effects: " .. (IRFConfig.blackBonyBombs and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.blackBonyBombs = bool
	    end,
	    Info = {"Black Bonies will spawn with random bomb effects."}
  	})
	-- Burning Gushers
	ModConfigMenu.AddSetting(category, "General", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.burningGushers
		end,
	    Display = function()
			return "Unique Burning Gushers: " .. (IRFConfig.burningGushers and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.burningGushers = bool
	    end,
	    Info = {"Gushers spawned by Flaming Gapers will have unique behaviour. (They will only have new sprites if turned off)"}
  	})


	-- Hidden enemy visuals --
	ModConfigMenu.AddText(category, "Indicators", function() return "-- Hidden enemy visuals --" end)

	-- Pins
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.noHiddenPins
		end,
	    Display = function()
			return "Pin: " .. (IRFConfig.noHiddenPins and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.noHiddenPins = bool
	    end
  	})
	-- Polycephalus
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.noHiddenPoly
		end,
	    Display = function()
			return "Polycephalus: " .. (IRFConfig.noHiddenPoly and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.noHiddenPoly = bool
	    end
  	})
	-- Dust
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.noHiddenDust
		end,
	    Display = function()
			return "Dust: " .. (IRFConfig.noHiddenDust and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.noHiddenDust = bool
	    end
  	})


	-- Extra appear animations --
	ModConfigMenu.AddSpace(category, "Indicators")
	ModConfigMenu.AddText(category, "Indicators", function() return "-- Extra appear animations --" end)
	
	-- Pins
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.appearPins
		end,
	    Display = function()
			return "Pin: " .. (IRFConfig.appearPins and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.appearPins = bool
	    end
  	})
	-- Mom's Hands
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.appearMomsHands
		end,
	    Display = function()
			return "Mom's Hands: " .. (IRFConfig.appearMomsHands and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.appearMomsHands = bool
	    end
  	})
	-- Needles
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.appearNeedles
		end,
	    Display = function()
			return "Needles: " .. (IRFConfig.appearNeedles and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.appearNeedles = bool
	    end
  	})


	-- Extra appear animations --
	ModConfigMenu.AddSpace(category, "Indicators")
	ModConfigMenu.AddText(category, "Indicators", function() return "-- Laser indicators --" end)

	-- Eyes
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.laserEyes
		end,
	    Display = function()
			return "Eyes: " .. (IRFConfig.laserEyes and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.laserEyes = bool
	    end
  	})
	-- Red Ghost
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFConfig.laserRedGhost
		end,
	    Display = function()
			return "Red Ghost: " .. (IRFConfig.laserRedGhost and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFConfig.laserRedGhost = bool
	    end
  	})
end