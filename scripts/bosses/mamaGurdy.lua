local mod = BetterMonsters

local Settings = {
	Cooldown = 45,
	SpikeCount = 15,
	WormCount = 6
}



function mod:mamaGurdyUpdate(entity)
	if entity.Variant == 0 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()


		-- Replace default projectile attacks
		if entity.State == NpcState.STATE_ATTACK then
			entity.State = NpcState.STATE_ATTACK5
			entity.I2 = mod:Random(1)
			--entity.I2 = 2

			if entity.I2 == 2 then
				for i = -1, 1, 2 do
					local basePos = Vector(target.Position.X + i * 120, room:GetTopLeftPos().Y + 20)

					for j = 0, room:GetGridHeight() - 3 do
						local pos = basePos + Vector(0, j * 40)

						if room:IsPositionInRoom(pos, 10) then
							local flip = false
							if i == 1 then
								flip = true
							end
							Isaac.Spawn(IRFentities.Type, IRFentities.GiantSpike, 0, pos, Vector.Zero, entity.SpawnerEntity):GetSprite().FlipX = flip
						end
					end
				end
			end

		-- Custom projectile attacks
		elseif entity.State == NpcState.STATE_ATTACK5 then
			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF)

				-- Bouncing shots
				if entity.I2 == 0 then
					local params = ProjectileParams()
					params.BulletFlags = ProjectileFlags.BOUNCE
					params.Scale = 1.5
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.13

					for i, projectile in pairs(mod:FireProjectiles(entity, entity.Position, (target.Position - entity.Position):Resized(9), 5, params)) do
						mod:QuickTrail(projectile, 0.09, Color(1,0.25,0.25, 1), projectile.Scale * 1.6)
					end

				-- Burst shots
				elseif entity.I2 == 1 then
					local params = ProjectileParams()
					params.BulletFlags = (ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.CHANGE_VELOCITY_AFTER_TIMEOUT)
					params.ChangeFlags = ProjectileFlags.BURST
					params.ChangeVelocity = 10
					params.ChangeTimeout = 40
					params.Scale = 2
					params.Acceleration = 1.025
					params.FallingAccelModifier = -0.2
					mod:FireProjectiles(entity, entity.Position, (target.Position - entity.Position):Resized(9), 3, params, Color.Default)

				-- Spike trap attack
				elseif entity.I2 == 2 then
					
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
				entity.StateFrame = Settings.Cooldown
			end


		-- Replace spikes from off-screen attack with Para-Bites
		elseif entity.State == NpcState.STATE_ATTACK3 and entity.I1 > 1 then
			local wormCount = Isaac.CountEntities(entity, EntityType.ENTITY_PARA_BITE, -1, -1)

			if wormCount > 0 then
				entity.I1 = 4 -- Doesn't do anything
			else
				entity.I1 = 2
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.mamaGurdyUpdate, EntityType.ENTITY_MAMA_GURDY)

-- Replace default spikes
function mod:mamaGurdySpawns(entity)
	if entity.SpawnerType == EntityType.ENTITY_MAMA_GURDY and entity.Type == EntityType.ENTITY_EFFECT and entity.Variant == EffectVariant.SPIKE then
		entity.Visible = false
		entity:Remove()


		local spawner = entity.SpawnerEntity:ToNPC()

		-- Giant spikes
		if spawner.State == NpcState.STATE_ATTACK2 then
			-- Only spawn a set amount of big spikes
			local spikeCount = Isaac.CountEntities(spawner, IRFentities.Type, IRFentities.GiantSpike, -1)

			if spikeCount < Settings.SpikeCount then
				local room = Game():GetRoom()
				local pos = room:FindFreePickupSpawnPosition(entity.Position, 0, true, false)

				-- One of them always spawns under the player
				if spikeCount == 0 then
					pos = spawner:GetPlayerTarget().Position
					pos = room:GetGridPosition(room:GetGridIndex(pos))
				end

				Isaac.Spawn(IRFentities.Type, IRFentities.GiantSpike, 0, pos, Vector.Zero, spawner)
			end


		-- Para-Bites
		elseif spawner.State == NpcState.STATE_ATTACK3 then
			-- Only spawn a set amount of worms
			local wormCount = Isaac.CountEntities(spawner, EntityType.ENTITY_PARA_BITE, -1, -1)

			if wormCount < Settings.WormCount and entity.Position:Distance(Game():GetNearestPlayer(entity.Position).Position) >= 100 then
				-- Have a chance to spawn Scarred Para-Bites in the Scarred Womb
				local variant = 0
				if Game():GetLevel():GetStageType() == StageType.STAGETYPE_AFTERBIRTH and mod:Random(2) == 1 then
					variant = 1
				end

				local pos = Game():GetRoom():FindFreePickupSpawnPosition(entity.Position, 0, true, false)
				Isaac.Spawn(EntityType.ENTITY_PARA_BITE, variant, 0, pos, Vector.Zero, spawner)
			end

			mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.mamaGurdySpawns)

-- Burst projectile fix
function mod:mamaGurdyProjectileUpdate(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_MAMA_GURDY and projectile:HasProjectileFlags(ProjectileFlags.BURST) then
		projectile:Die()
		mod:PlaySound(nil, SoundEffect.SOUND_DEATH_BURST_SMALL)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.mamaGurdyProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)