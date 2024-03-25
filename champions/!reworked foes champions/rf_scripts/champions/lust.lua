local mod = ReworkedFoes

local Settings = {
	CreepTime = 120,
	StrengthScale = 1.15,
	StrengthHPMulti = 1.3,
	DeathOrbitalCount = 5,
}



--[[ Effect functions ]]--
-- Hanged Man
function mod:LustHangedMan(entity)
	entity:GetData().hanged = true
	entity:GetData().tryGoOverObstacles = true
	entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
end


-- Hermit
function mod:LustHermit(entity)
	entity:GetData().greedy = true
	mod:LustPrettyFly(entity)

	-- Load the new sprites
	local sprite = entity:GetSprite()
	for i = 0, 1 do
		sprite:ReplaceSpritesheet(i, "gfx/bosses/classic/miniboss_07_lust_fortune_teller_hermit.png")
	end
	sprite:LoadGraphics()

	-- Effects
	mod:PlaySound(nil, SoundEffect.SOUND_BLACK_POOF)

	local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, entity):GetSprite()
	effect.Color = Color(0.5,0.5,0.5, 1)
	effect.Scale = Vector.One * entity.Scale
end


-- Temperance
function mod:LustTemperanceActivate(entity)
	mod:PlaySound(nil, SoundEffect.SOUND_BLOODBANK_SPAWN)
	mod:ShootEffect(entity, 3, Vector.Zero, Color.Default, entity.Scale, true)
end

function mod:LustTemperancePassive(entity)
	-- Creep
	if entity:IsFrame(4, 0) then
		mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, entity.Scale, Settings.CreepTime)
	end
	-- Projectiles
	if entity:IsFrame(7, 0) then
		entity:FireBossProjectiles(1, Vector.Zero, 4, ProjectileParams())
	end
end


-- Strength
function mod:LustStrength(entity)
	entity.Scale = entity.Scale * Settings.StrengthScale
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

	-- HP up
	local multi = Settings.StrengthHPMulti
	entity.MaxHitPoints = entity.MaxHitPoints * multi
	entity.HitPoints = entity.HitPoints * multi
end


-- Death
function mod:LustDeathCard(entity)
	if entity.HitPoints <= entity.MaxHitPoints - (entity.MaxHitPoints / Settings.DeathOrbitalCount) * entity.I2
	and not entity:IsDead() then
		entity.I2 = entity.I2 + 1
		Isaac.Spawn(mod.Entities.Type, mod.Entities.BoneOrbital, 0, entity.Position, Vector.Zero, entity).Parent = entity

		-- Effects
		mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND, 0.8)

		local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 1, entity.Position, Vector.Zero, entity):GetSprite()
		effect.Color = Color(0,0,0, 0.5)
		effect.Scale = Vector.One * 0.75
	end
end



--[[ Define the effects ]]--
local effects = {
	{ SFX = SoundEffect.SOUND_HANGED_MAN, Anim = "HangedMan",  Activate = mod.LustHangedMan },
	{ SFX = SoundEffect.SOUND_HERMIT, 	  Anim = "Hermit",     Activate = mod.LustHermit, Passive = mod.CollectCoins },
	{ SFX = SoundEffect.SOUND_TEMPERANCE, Anim = "Temperance", Activate = mod.LustTemperanceActivate, Passive = mod.LustTemperancePassive },
	{ SFX = SoundEffect.SOUND_STRENGTH,   Anim = "Strength",   Activate = mod.LustStrength },
	{ SFX = SoundEffect.SOUND_DEATH, 	  Anim = "Death", 	   Passive  = mod.LustDeathCard },
}
mod.LustEffects[0][mod.Champions.Lust] = effects