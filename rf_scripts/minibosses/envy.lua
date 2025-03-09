local mod = ReworkedFoes

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



function mod:EnvyUpdate(entity)
	if mod:CheckValidMiniboss() and mod.Config.EnvyRework then
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

		-- Disable the default AI when bouncing
		if not entity:HasMortalDamage() and entity.FrameCount ~= 0 and entity.I2 == 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.EnvyUpdate, EntityType.ENTITY_ENVY)

function mod:EnvyCollision(entity, target, bool)
	if mod:CheckValidMiniboss() and mod.Config.EnvyRework
	and target.Type == EntityType.ENTITY_ENVY and (entity.I1 == 1 or entity.Variant <= 1) then
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
		if mod:IsRFChampion(entity, "Envy") and bool == true then
			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_TEAR

			for i = -1, 1, 2 do
				entity:FireProjectiles(entity.Position, (entity.Position - target.Position):Rotated(i * 90):Resized(Settings.BaseShotSpeed + strength), 0, params)
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.EnvyCollision, EntityType.ENTITY_ENVY)

-- Pink champion projectiles
function mod:EnvyDeath(entity)
	if mod:CheckValidMiniboss() and mod:IsRFChampion(entity, "Envy")
	and (entity.Variant == 0 or (not mod.Config.EnvyRework and (entity.Variant == 10 or entity.Variant == 20))) then
		local amount = 8 - (entity.Variant / 10) * 2

		local params = ProjectileParams()
		params.Variant = ProjectileVariant.PROJECTILE_TEAR
		params.CircleAngle = 0
		entity:FireProjectiles(entity.Position, Vector(Settings.BaseShotSpeed + 1, amount), 9, params)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.EnvyDeath, EntityType.ENTITY_ENVY)



function mod:EnvyRewards(pickup)
	-- Trinkets
	if pickup.SpawnerType == EntityType.ENTITY_ENVY
	and pickup.Variant == PickupVariant.PICKUP_BOMB and pickup.SubType == BombSubType.BOMB_TROLL then
		pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, 0, false, true, false)
	end

	-- Tammy's Head
	if mod:CheckMinibossDropReplacement(pickup, EntityType.ENTITY_ENVY, "Envy")
	and pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and pickup.SubType ~= CollectibleType.COLLECTIBLE_TAMMYS_HEAD then
		pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_TAMMYS_HEAD, false, true, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.EnvyRewards)