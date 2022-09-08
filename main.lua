BetterMonsters = RegisterMod("Better Vanilla Monsters", 1)
local mod = BetterMonsters
local game = Game()
local json = require("json")

-- Useful colors & values --
sunBeamColor = Color(1,1,1, 1, 0.3,0.3,0)
ghostGibs = Color(1,1,1, 0.25, 1,1,1)
brimstoneBulletColor = Color(1,0.25,0.25, 1, 0.25,0,0)

tarBulletColor = Color(0.5,0.5,0.5, 1, 0,0,0)
tarBulletColor:SetColorize(1, 1, 1, 1)

skyBulletColor = Color(1,1,1, 1, 0.5,0.5,0.5)
skyBulletColor:SetColorize(1, 1, 1, 1)

greenBulletColor = Color(1,1,1, 1, 0,0,0)
greenBulletColor:SetColorize(0, 1, 0, 1)



-- Mod config menu --
IRFconfig = {
	-- General
	breakableHosts = true,
	blackBonyCostumes = true,
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
function mod:preGameExit() mod:SaveData(json.encode(IRFconfig)) end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.preGameExit)

-- Menu options
if ModConfigMenu then
  	local category = "Reworked Foes"
	ModConfigMenu.RemoveCategory(category);
  	ModConfigMenu.UpdateCategory(category, {
		Name = category,
		Info = "Change settings for Improved & Reworked Foes"
	})
	
	-- General settings
	ModConfigMenu.AddSetting(category, "General", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function() return IRFconfig.breakableHosts end,
	    Display = function() return "Breakable hosts: " .. (IRFconfig.breakableHosts and "True" or "False") end,
	    OnChange = function(bool)
	    	IRFconfig.breakableHosts = bool
	    end,
	    Info = {"Enable/Disable breakable hosts. (default = true)"}
  	})
	ModConfigMenu.AddSetting(category, "General", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function() return IRFconfig.blackBonyCostumes end,
	    Display = function() return "Black Bony Indicator: " .. (IRFconfig.blackBonyCostumes and "Head Costume" or "Icon") end,
	    OnChange = function(bool)
	    	IRFconfig.blackBonyCostumes = bool
	    end,
	    Info = {"Black Bony bomb type indicator. (default = Head Costume)"}
  	})
end



-- External scripts --
include("scripts.flamingGaper")
include("scripts.clotty")
include("scripts.drownedHive")
include("scripts.drownedCharger")
include("scripts.dankGlobin")
include("scripts.drownedBoomFly")
include("scripts.host")
--include("scripts.chad")
include("scripts.hopper")
include("scripts.redMaw")
include("scripts.angelicBaby")
include("scripts.chubber")
--include("scripts.scarredGuts")
include("scripts.selflessKnight")
include("scripts.pokies")
--include("scripts.monstro2")
include("scripts.gish")
include("scripts.sloth")
include("scripts.lust")
include("scripts.wrath")
include("scripts.gluttony")
include("scripts.greed")
include("scripts.envy")
include("scripts.pride")
include("scripts.holyLeech")
include("scripts.lump")
include("scripts.membrain")
--include("scripts.scarredParaBite")
include("scripts.eye")
include("scripts.conquest")
include("scripts.bloat")
include("scripts.lokii")
--include("scripts.teratoma")
include("scripts.steven")
include("scripts.blightedOvum")
include("scripts.fallen")
include("scripts.headlessHorseman")
include("scripts.satan")
include("scripts.spiders")
include("scripts.eternalFly") 
include("scripts.maskInfamy")
--include("scripts.wretched")
--include("scripts.blueBaby")
include("scripts.daddyLongLegs")
include("scripts.flamingFatty")
include("scripts.dankDeathsHead")
--include("scripts.momsHand")
include("scripts.ghosts")
include("scripts.codWorm")
include("scripts.skinny")
include("scripts.camilloJr")
include("scripts.nerveEnding2")
include("scripts.noKnockback")
--include("scripts.psyTumor")
include("scripts.fatBat")
include("scripts.megaMaw")
include("scripts.ragling")
--include("scripts.floatingKnight")
include("scripts.dartFly")
include("scripts.blackBony")
include("scripts.blackGlobin")
include("scripts.megaClotty")
--include("scripts.boneKnight")
include("scripts.fleshDeathHead")
include("scripts.blister")
include("scripts.portal")
--include("scripts.stain")
include("scripts.forsaken")
--include("scripts.ragMega")
--include("scripts.sisterVis")
include("scripts.bossHealthBars")