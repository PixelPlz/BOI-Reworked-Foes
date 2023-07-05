local mod = BetterMonsters

local Settings = {
	Cooldown = 50,
	SpikeCount = 14,
	WormCount = 5
}



function mod:mamaGurdyUpdate(entity)
	if entity.Variant == 0 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()


		-- Replace default projectile attacks
		if entity.State == NpcState.STATE_ATTACK then
			if sprite:GetFrame() == 0 then
				entity.I1 = mod:Random(10, 11)
			end

			-- Spike trap attack
			if entity.I1 == 11 then
				entity.State = NpcState.STATE_ATTACK5
				entity.I1 = 0
				entity.ProjectileCooldown = 0

				-- Spawn spike walls on both sides
				for i = -1, 1, 2 do
					local basePos = Vector(target.Position.X + i * 120, room:GetTopLeftPos().Y + 20)

					for j = 0, room:GetGridHeight() - 3 do
						local pos = basePos + Vector(0, j * 40)

						if room:IsPositionInRoom(pos, 10) then
							local flip = false
							if i == 1 then
								flip = true
							end
							Isaac.Spawn(IRFentities.Type, IRFentities.GiantSpike, 0, pos, Vector.Zero, entity):GetSprite().FlipX = flip
						end
					end
				end


			-- Custom projectile attack
			elseif sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF)

				-- Bouncing shots
				if entity.I1 == 10 then
					local params = ProjectileParams()
					params.Scale = 1.75
					params.Color = IRFcolors.PukeOrange
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.13

					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(9), 5, params)

					params.Spread = 0.77
					params.BulletFlags = ProjectileFlags.BOUNCE
					for i, projectile in pairs(mod:FireProjectiles(entity, entity.Position, (target.Position - entity.Position):Resized(7), 4, params)) do
						mod:QuickTrail(projectile, 0.09, Color(0.64,0.4,0.16, 1), projectile.Scale * 1.6)
					end

				-- Burst shots
				elseif entity.I1 == 11 then
					local params = ProjectileParams()
					params.BulletFlags = (ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.CHANGE_VELOCITY_AFTER_TIMEOUT)
					params.ChangeFlags = ProjectileFlags.BURST
					params.ChangeVelocity = 10
					params.ChangeTimeout = 40
					params.Scale = 2
					params.Acceleration = 1.04
					params.FallingAccelModifier = -0.2
					mod:FireProjectiles(entity, entity.Position, (target.Position - entity.Position):Resized(9), 3, params, Color.Default)
				end
			end


		-- Spike trap attack
		elseif entity.State == NpcState.STATE_ATTACK5 then
			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF)
			end

			if sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("ShootStop") then
				if entity.ProjectileCooldown <= 0 then
					local params = ProjectileParams()
					params.Scale = 1.5
					params.Color = IRFcolors.PukeOrange
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.13
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(7), 5 - entity.I1, params)
					entity.ProjectileCooldown = 6
					entity.I1 = entity.I1 + 1

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
				entity.StateFrame = Settings.Cooldown
			end


		-- Stay hidden if there are worms alive
		elseif entity.State == NpcState.STATE_ATTACK3 then
			if sprite:IsPlaying("Attack1") and sprite:GetFrame() == 2 then
				entity.ProjectileDelay = Settings.Cooldown / 2
			end

			if entity.I1 > 1 then
				if Isaac.CountEntities(entity, EntityType.ENTITY_PARA_BITE, -1, -1) > 0 then
					entity.I1 = 4 -- Doesn't do anything
					sprite:SetFrame(0)

					-- Spawn spikes in random places
					if entity.ProjectileDelay <= 0 then
						for i = 0, 2 do
							Isaac.Spawn(IRFentities.Type, IRFentities.GiantSpike, 0, room:FindFreePickupSpawnPosition(Isaac:GetRandomPosition(), 0, true, false), Vector.Zero, entity)
						end
						entity.ProjectileDelay = Settings.Cooldown

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

				-- Come down if all worms are dead
				else
					entity.I1 = 2
				end
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