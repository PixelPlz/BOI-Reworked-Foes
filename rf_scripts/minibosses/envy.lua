local mod = BetterMonsters

local Settings = {
	InitialSpeed = 7,
	BaseStrength = 1,
	MaxStrength = 12,

	InitialTimer = 60,
	BaseTimer = 30,

	BaseMulti = 0.1,
	BaseDiv = 0.05,

	BaseVolume = 2,
	BaseShotSpeed = 6.5
}



function mod:envyUpdate(entity)
	if mod:CheckForRev() == false and IRFConfig.envyRework == true then
		if entity.Variant >= 10 and entity.FrameCount == 0 then
			entity.I2 = 1
			entity.ProjectileCooldown = Settings.InitialTimer
		end

		-- Bounce timer
		if entity.ProjectileCooldown <= 0 then
			entity.I2 = 0
		else
			-- Give initial speed
			if entity.ProjectileCooldown == Settings.InitialTimer - 1 and entity.I1 == 0 and entity.SpawnerEntity then
				entity.Velocity = (entity.Position - entity.SpawnerEntity.Position):Resized(Settings.InitialSpeed)
				entity.I1 = 1
			end
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end

		-- Disable AI when bouncing
		if not entity:HasMortalDamage() and entity.FrameCount ~= 0 and entity.I2 == 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.envyUpdate, EntityType.ENTITY_ENVY)

function mod:envyCollide(entity, target, bool)
	if mod:CheckForRev() == false and IRFConfig.envyRework == true and target.Type == EntityType.ENTITY_ENVY and (entity.I1 == 1 or entity.Variant < 2) then
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
		local bounce = math.min(Settings.MaxStrength, entity.Velocity:Length() * strength)

		entity.Velocity = (entity.Position - target.Position):Resized(bounce)
		mod:PlaySound(nil, SoundEffect.SOUND_DEATH_BURST_LARGE, Settings.BaseVolume - strength, 1.1)


		-- Champion shots
		if entity.SubType == 1 and bool == true then
			for i = -1, 1, 2 do
				entity:FireProjectiles(entity.Position, (entity.Position - target.Position):Rotated(i * 90):Resized(Settings.BaseShotSpeed + strength), 0, ProjectileParams())
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.envyCollide, EntityType.ENTITY_ENVY)

function mod:envyDeath(entity)
	if mod:CheckForRev() == false and entity.SubType == 1
	and (entity.Variant == 0 or (IRFConfig.envyRework == false and (entity.Variant == 10 or entity.Variant == 20))) then
		local amount = 8 - (entity.Variant / 10) * 2

		local params = ProjectileParams()
		params.CircleAngle = 0
		entity:FireProjectiles(entity.Position, Vector(Settings.BaseShotSpeed + 1, amount), 9, params)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.envyDeath, EntityType.ENTITY_ENVY)



function mod:envyRewards(entity)
	if mod:CheckForRev() == false and entity.SpawnerType == EntityType.ENTITY_ENVY then
		-- Tammy's Head
		if entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity.SubType ~= CollectibleType.COLLECTIBLE_TAMMYS_HEAD then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_TAMMYS_HEAD, false, true, false)

		-- Trinkets
		elseif entity.Variant == PickupVariant.PICKUP_BOMB and entity.SubType == BombSubType.BOMB_TROLL then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, 0, false, true, false)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.envyRewards)