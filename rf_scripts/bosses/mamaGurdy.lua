local mod = ReworkedFoes

local Settings = {
	Cooldown = 50,
	SpikeCount = 14,
	WormCount = 5
}



function mod:MamaGurdyUpdate(entity)
	if entity.Variant == 0 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local room = Game():GetRoom()

		local shootPos = entity.Position + Vector(0, 15)


		-- Replace default projectile attacks
		if entity.State == NpcState.STATE_ATTACK then
			if sprite:GetFrame() == 0 then
				if entity:GetData().wasDelirium then
					entity.I1 = 10
				else
					entity.I1 = mod:Random(10, 11)
				end
			end

			-- Spike trap attack
			if entity.I1 == 11 then
				entity.State = NpcState.STATE_ATTACK5
				sprite:Play("Attack2", true)
				entity.I1 = 0
				entity.I2 = 0
				entity.ProjectileCooldown = 0
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR)


			-- Bouncing shots attack
			elseif sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Scale = 1.75
				params.Color = mod.Colors.PukeOrange
				params.FallingSpeedModifier = 1
				params.FallingAccelModifier = -0.13

				entity:FireProjectiles(shootPos, (target.Position - shootPos):Resized(9), 5, params)

				params.Spread = 0.77
				params.BulletFlags = ProjectileFlags.BOUNCE
				for i, projectile in pairs(mod:FireProjectiles(entity, shootPos, (target.Position - shootPos):Resized(7), 4, params)) do
					mod:QuickTrail(projectile, 0.09, Color(0.64,0.4,0.16, 1), projectile.Scale * 1.6)
				end

				mod:ShootEffect(entity, 4, Vector(0, 8), mod.Colors.PukeOrange)
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF)
			end


		-- Spike trap attack
		elseif entity.State == NpcState.STATE_ATTACK5 then
			-- Slam the ground
			if entity.I2 == 0 then
				-- Spawn spike walls on both sides
				if sprite:IsEventTriggered("Shoot") then
					Game():ShakeScreen(8)
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.1)
					mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1.1)

					for i = -1, 1, 2 do
						-- Effects
						local handPos = entity.Position + Vector(i * 140, 40)
						Game():MakeShockwave(handPos, 0.035, 0.025, 10)
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, handPos, Vector.Zero, entity):GetSprite().Color = mod.Colors.DustPoof

						-- Spike walls
						local basePos = Vector(target.Position.X + i * 120, room:GetTopLeftPos().Y + 20)
						for j = 0, room:GetGridHeight() - 3 do
							local pos = basePos + Vector(0, j * 40)

							-- Don't spawn them out of bounds
							if room:IsPositionInRoom(pos, 10) then
								local spike = Isaac.Spawn(mod.Entities.Type, mod.Entities.GiantSpike, 0, pos, Vector.Zero, entity):ToNPC()
								spike.State = NpcState.STATE_ATTACK
								spike:GetSprite():Play("Extend", true)
								spike:GetSprite().FlipX = i == 1
								spike.I2 = 90
							end
						end
					end
				end

				if sprite:IsFinished() then
					entity.I2 = 1
					sprite:Play("Shoot", true)
				end

			-- Shoot
			elseif entity.I2 == 1 then
				if sprite:IsEventTriggered("Shoot") then
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF)
				end

				-- Only shoot 3 spreads
				if sprite:WasEventTriggered("Shoot") and entity.I1 < 3 then
					if entity.ProjectileCooldown <= 0 then
						local params = ProjectileParams()
						params.Scale = 1.5
						params.Color = mod.Colors.PukeOrange
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.13
						params.Spread = 1.1
						entity:FireProjectiles(shootPos, (target.Position - shootPos):Resized(6.5), 5 - entity.I1, params)
						mod:ShootEffect(entity, 4, Vector(0, 8), mod.Colors.PukeOrange)

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
			end


		-- Off-screen / Puke attack
		elseif entity.State == NpcState.STATE_ATTACK3 then
			-- Set starting spike cooldown
			if sprite:IsPlaying("Attack1") and sprite:GetFrame() == 2 then
				entity.ProjectileDelay = Settings.Cooldown / 2

			-- Puke effects
			elseif sprite:IsPlaying("Puke") and sprite:WasEventTriggered("Shoot") and entity:IsFrame(5, 0) and not sprite:WasEventTriggered("BloodStop") and sprite:GetFrame() < 65 then
				mod:ShootEffect(entity, 4, Vector(0, 8), mod.Colors.PukeOrange)
			end


			-- Stay hidden if there are worms alive
			if entity.I1 > 1 then
				if Isaac.CountEntities(entity, EntityType.ENTITY_PARA_BITE, -1, -1) > 0 then
					entity.I1 = 4 -- Doesn't do anything
					sprite:SetFrame(0)

					-- Spawn spikes in random places
					if entity.ProjectileDelay <= 0 then
						for i = 0, 2 do
							Isaac.Spawn(mod.Entities.Type, mod.Entities.GiantSpike, 0, room:FindFreePickupSpawnPosition(Isaac:GetRandomPosition(), 0, true, false), Vector.Zero, entity)
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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MamaGurdyUpdate, EntityType.ENTITY_MAMA_GURDY)

-- Replace default spikes
function mod:MamaGurdySpawns(effect)
	if effect.SpawnerType == EntityType.ENTITY_MAMA_GURDY then
		effect.Visible = false
		effect:Remove()


		local spawner = effect.SpawnerEntity:ToNPC()

		-- Giant spikes
		if spawner.State == NpcState.STATE_ATTACK2 then
			-- Only spawn a set amount of big spikes
			local spikeCount = Isaac.CountEntities(spawner, mod.Entities.Type, mod.Entities.GiantSpike, -1)

			if spikeCount < Settings.SpikeCount then
				local room = Game():GetRoom()
				local pos = room:FindFreePickupSpawnPosition(effect.Position, 0, true, false)

				-- One of them always spawns under the player
				if spikeCount == 0 then
					pos = spawner:GetPlayerTarget().Position
					pos = room:GetGridPosition(room:GetGridIndex(pos))
				end

				Isaac.Spawn(mod.Entities.Type, mod.Entities.GiantSpike, 0, pos, Vector.Zero, spawner)
			end


		-- Para-Bites
		elseif spawner.State == NpcState.STATE_ATTACK3 then
			-- Only spawn a set amount of worms
			local wormCount = Isaac.CountEntities(spawner, EntityType.ENTITY_PARA_BITE, -1, -1)

			if wormCount < Settings.WormCount and effect.Position:Distance(Game():GetNearestPlayer(effect.Position).Position) >= 100 then
				-- Have a chance to spawn Scarred Para-Bites in the Scarred Womb
				local variant = 0
				if Game():GetLevel():GetStageType() == StageType.STAGETYPE_AFTERBIRTH and mod:Random(2) == 1 then
					variant = 1
				end

				local pos = Game():GetRoom():FindFreePickupSpawnPosition(effect.Position, 0, true, false)
				local worm = Isaac.Spawn(EntityType.ENTITY_PARA_BITE, variant, 0, pos, Vector.Zero, spawner):ToNPC()
				worm:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				worm.State = NpcState.STATE_SPECIAL
				worm:GetSprite():Play("DigOut", true)
			end

			mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.MamaGurdySpawns, EffectVariant.SPIKE)