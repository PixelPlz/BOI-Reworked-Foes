local mod = BetterMonsters
local game = Game()

local Settings = {
	InitialSpeed = 8,
	InitialTimer = 60,
	BaseStrength = 1.2,
	BaseTimer = 30,
	BaseMulti = 0.1,
	BaseDiv = 0.05,
	MaxStrength = 16,
	BaseVolume = 2.2,
	BaseShotSpeed = 7.5
}



function mod:envyUpdate(entity)
	if entity.Variant >= 10 and entity.FrameCount == 0 then
		entity.I2 = 1
		entity.ProjectileCooldown = Settings.InitialTimer
	end

	-- Bounce timer
	if entity.ProjectileCooldown <= 0 then
		entity.I2 = 0
	else
		-- Give initial speed
		if entity.ProjectileCooldown == Settings.InitialTimer - 1 and entity.I1 == 0 then
			entity.Velocity = (entity.Position - entity.SpawnerEntity.Position):Normalized() * Settings.InitialSpeed
			entity.I1 = 1
		end
		entity.ProjectileCooldown = entity.ProjectileCooldown - 1
	end

	-- Disable AI when bouncing
	if not entity:HasMortalDamage() and entity.FrameCount ~= 0 and entity.I2 == 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.envyUpdate, EntityType.ENTITY_ENVY)

function mod:envyCollide(entity, target, bool)
	if target.Type == EntityType.ENTITY_ENVY and (entity.I1 == 1 or entity.Variant < 2) then
		-- Get bounce strength
		local eSize = math.floor(entity.Variant / 10)
		local tSize = math.floor(target.Variant / 10)
		local strength = Settings.BaseStrength + (eSize + tSize) / 10

		if eSize > tSize then
			strength = strength + (tSize * Settings.BaseMulti)
		elseif eSize < tSize then
			strength = strength - (tSize * Settings.BaseDiv)
		end
		
		-- Go to bouncing state, set timer
		entity.I2 = 1
		entity.ProjectileCooldown = math.ceil(Settings.BaseTimer * strength)
		
		-- Make sure they don't go too fast
		local bounce = (entity.Velocity:Length() * strength)
		if ((entity.Position - target.Position):Normalized() * bounce):Length() > Settings.MaxStrength then
			entity.Velocity = (entity.Position - target.Position):Normalized() * Settings.MaxStrength
		else
			entity.Velocity = (entity.Position - target.Position):Normalized() * bounce
		end
		
		-- Champion shots
		if entity.SubType == 1 and bool == true then
			entity:FireProjectiles(entity.Position, Vector(Settings.BaseShotSpeed + strength, 0), 6, ProjectileParams())
		end

		SFXManager():Play(SoundEffect.SOUND_DEATH_BURST_LARGE, Settings.BaseVolume - strength, 0, false, 1.1)
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.envyCollide, EntityType.ENTITY_ENVY)

function mod:envyDeath(entity)
	if entity.Variant == 0 and entity.SubType == 1 then
		entity:FireProjectiles(entity.Position, Vector(Settings.BaseShotSpeed, 0), 8, ProjectileParams())
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.envyDeath, EntityType.ENTITY_ENVY)



function mod:envyRewards(entity)
	if entity.SpawnerType == EntityType.ENTITY_ENVY then
		-- Tammy's Head
		if entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity.SubType ~= 38 then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 38, false, true, false)

		-- Trinkets
		elseif entity.Variant == PickupVariant.PICKUP_BOMB and entity.SubType == BombSubType.BOMB_TROLL then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, 0, false, true, false)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.envyRewards)