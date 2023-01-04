local mod = BetterMonsters
local json = require("json")

IRFconfig = {
	-- General
	breakableHosts   = true,
	noChapter1Nests  = true,
	matriarchFistula = true,
	
	-- Hidden enemy visuals
	noHiddenPins  = true,
	noHiddenPoly  = true,
	noHiddenStain = true,
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
            if IRFconfig[k] ~= nil then IRFconfig[k] = v end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.postGameStarted)

-- Save settings
function mod:preGameExit()
	mod:SaveData(json.encode(IRFconfig))
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
			return IRFconfig.breakableHosts
		end,
	    Display = function()
			return "Breakable Hosts: " .. (IRFconfig.breakableHosts and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFconfig.breakableHosts = bool
	    end,
		Info = {"Host armor will break if they get bombed or take more than their max HP in damage at once."}
  	})
	-- Ch.1 Nests
	ModConfigMenu.AddSetting(category, "General", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFconfig.noChapter1Nests
		end,
	    Display = function()
			return "Replace Nests in Chapter 1: " .. (IRFconfig.noChapter1Nests and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFconfig.noChapter1Nests = bool
	    end,
	    Info = {"Nests in the first two floors will be replaced by easier Mullicocoons."}
  	})
	-- Matriarch Fistulas
	ModConfigMenu.AddSetting(category, "General", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFconfig.matriarchFistula
		end,
	    Display = function()
			return "Matriarch Fistulas: " .. (IRFconfig.matriarchFistula and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFconfig.matriarchFistula = bool
	    end,
	    Info = {"Better colors for Fistulas spawned by the Matriarch."}
  	})


	-- Hidden enemy visuals --
	ModConfigMenu.AddText(category, "Indicators", function() return "-- Hidden enemy visuals --" end)

	-- Pins
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFconfig.noHiddenPins
		end,
	    Display = function()
			return "Pin: " .. (IRFconfig.noHiddenPins and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFconfig.noHiddenPins = bool
	    end
  	})
	-- Polycephalus
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFconfig.noHiddenPoly
		end,
	    Display = function()
			return "Polycephalus: " .. (IRFconfig.noHiddenPoly and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFconfig.noHiddenPoly = bool
	    end
  	})
	-- The Stain
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFconfig.noHiddenStain
		end,
	    Display = function()
			return "The Stain: " .. (IRFconfig.noHiddenStain and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFconfig.noHiddenStain = bool
	    end
  	})
	-- Dust
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFconfig.noHiddenDust
		end,
	    Display = function()
			return "Dust: " .. (IRFconfig.noHiddenDust and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFconfig.noHiddenDust = bool
	    end
  	})


	-- Extra appear animations --
	ModConfigMenu.AddSpace(category, "Indicators")
	ModConfigMenu.AddText(category, "Indicators", function() return "-- Extra appear animations --" end)
	
	-- Pins
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFconfig.appearPins
		end,
	    Display = function()
			return "Pin: " .. (IRFconfig.appearPins and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFconfig.appearPins = bool
	    end
  	})
	-- Mom's Hands
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFconfig.appearMomsHands
		end,
	    Display = function()
			return "Mom's Hands: " .. (IRFconfig.appearMomsHands and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFconfig.appearMomsHands = bool
	    end
  	})
	-- Needles
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFconfig.appearNeedles
		end,
	    Display = function()
			return "Needles: " .. (IRFconfig.appearNeedles and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFconfig.appearNeedles = bool
	    end
  	})


	-- Extra appear animations --
	ModConfigMenu.AddSpace(category, "Indicators")
	ModConfigMenu.AddText(category, "Indicators", function() return "-- Laser indicators --" end)

	-- Eyes
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFconfig.laserEyes
		end,
	    Display = function()
			return "Eyes: " .. (IRFconfig.laserEyes and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFconfig.laserEyes = bool
	    end
  	})
	-- Red Ghost
	ModConfigMenu.AddSetting(category, "Indicators", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function()
			return IRFconfig.laserRedGhost
		end,
	    Display = function()
			return "Red Ghost: " .. (IRFconfig.laserRedGhost and "On" or "Off")
		end,
	    OnChange = function(bool)
	    	IRFconfig.laserRedGhost = bool
	    end
  	})
end