BetterMonsters = RegisterMod("Better Vanilla Monsters", 1)
local mod = BetterMonsters
local game = Game()
local json = require("json")

-- Useful colors & values --
IRFentities = {
	featherProjectile = Isaac.GetEntityVariantByName("Angelic Feather Projectile"),
	cocoonProjectile = Isaac.GetEntityVariantByName("Spider Cocoon Projectile"),
	bubbleFly = Isaac.GetEntityVariantByName("Bubble Fly"),
	cofferVariant = Isaac.GetEntityVariantByName("Coffer"),
	mullicocoonVariant = Isaac.GetEntityVariantByName("Mullicocoon"),
}

sunBeamColor = Color(1,1,1, 1, 0.3,0.3,0)
ghostGibs = Color(1,1,1, 0.25, 1,1,1)
brimstoneBulletColor = Color(1,0.25,0.25, 1, 0.25,0,0)

tarBulletColor = Color(0.5,0.5,0.5, 1, 0,0,0)
tarBulletColor:SetColorize(1, 1, 1, 1)

skyBulletColor = Color(1,1,1, 1, 0.5,0.5,0.5)
skyBulletColor:SetColorize(1, 1, 1, 1)

greenBulletColor = Color(1,1,1, 1, 0,0,0)
greenBulletColor:SetColorize(0, 1, 0, 1)

portalBulletColor = Color(0.5,0.5,0.7, 1, 0.05,0.05,0.125)
portalBulletTrail = Color(0.5,0.5,0.7, 1, 0,0.25,0.5)
portalSpawnColor = Color(0.2,0.2,0.3, 0, 1.5,0.75,3)



-- Mod config menu --
IRFconfig = {
	-- General
	breakableHosts = true,
	blackBonyCostumes = true,
	classicEternalFlies = true,
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
	    Display = function() return "Breakable hosts: " .. (IRFconfig.breakableHosts and "On" or "Off") end,
	    OnChange = function(bool)
	    	IRFconfig.breakableHosts = bool
	    end,
	    Info = {"Toggle breakable hosts. (default = on)"}
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
	ModConfigMenu.AddSetting(category, "General", {
    	Type = ModConfigMenu.OptionType.BOOLEAN,
	    CurrentSetting = function() return IRFconfig.classicEternalFlies end,
	    Display = function() return "Classic Eternal Flies: " .. (IRFconfig.classicEternalFlies and "On" or "Off") end,
	    OnChange = function(bool)
	    	IRFconfig.classicEternalFlies = bool
	    end,
	    Info = {"Toggle classic Eternal Flies. (default = on)"}
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
include("scripts.selflessKnight")
include("scripts.pokies")
--include("scripts.monstro2")
include("scripts.gish")
include("scripts.mom")
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
include("scripts.scarredParaBite")
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
include("scripts.nest")
include("scripts.flamingFatty")
include("scripts.dankDeathsHead")
include("scripts.momsHand")
include("scripts.ghosts")
include("scripts.codWorm")
include("scripts.skinny")
include("scripts.camilloJr")
include("scripts.nerveEnding2")
include("scripts.noKnockback")
include("scripts.psyTumor")
include("scripts.fatBat")
include("scripts.megaMaw")
include("scripts.fallenAngels")
include("scripts.ragling")
--include("scripts.floatingKnight")
include("scripts.dartFly")
include("scripts.blackBony")
include("scripts.blackGlobin")
include("scripts.megaClotty")
--include("scripts.boneKnight")
include("scripts.fleshDeathHead")
include("scripts.ulcer")
include("scripts.blister")
include("scripts.portal")
--include("scripts.stain")
include("scripts.forsaken")
--include("scripts.ragMega")
--include("scripts.sisterVis")
include("scripts.taintedFaceless")
include("scripts.projectiles")
include("scripts.bossHealthBars")



-- Useful functions
function mod:Lerp(first,second,percent)
	return (first + (second - first) * percent)
end

function mod:StopLerp(vector)
	return mod:Lerp(vector, Vector.Zero, 0.25)
end


function mod:LoopingAnim(sprite, anim)
	if not sprite:IsPlaying(anim) then
		sprite:Play(anim, true)
	end
end

function mod:LoopingOverlay(sprite, anim)
	if not sprite:IsOverlayPlaying(anim) then
		sprite:PlayOverlay(anim, true)
	end
end


function mod:QuickCreep(type, spawner, position, scale, timeout)
	local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, type, 0, position, Vector.Zero, spawner):ToEffect()
	if scale then
		creep.SpriteScale = Vector(scale, scale)
	end
	if timeout then
		creep:SetTimeout(timeout)
	end
	creep:Update()
end


function IRFfireRing(entity)
	local ring = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_JET, 40, entity.Position, Vector.Zero, entity)
	ring.DepthOffset = entity.DepthOffset - 10
	ring.SpriteScale = Vector(1.25, 1.25)
	SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_END)

	for i, e in pairs(Isaac.FindInRadius(entity.Position, 60, 40)) do
		local dmg = 0
		if e.Type == EntityType.ENTITY_PLAYER then
			dmg = 1
		end
		e:TakeDamage(dmg, DamageFlag.DAMAGE_FIRE, EntityRef(entity), 0)
	end
end