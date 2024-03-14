local mod = ReworkedFoes



function mod:SlothInit(entity)
	if mod:CheckValidMiniboss(entity) and mod:IsRFChampion(entity, "Sloth") then
		entity.SplatColor = mod.Colors.Tar
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.SlothInit, EntityType.ENTITY_SLOTH)

function mod:SlothUpdate(entity)
	if mod:CheckValidMiniboss(entity) then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()

		-- Replace default spawning attack
		if entity.State == NpcState.STATE_ATTACK then
			entity.State = NpcState.STATE_SUMMON

		-- Spawn
		elseif entity.State == NpcState.STATE_SUMMON then
			if sprite:GetFrame() == 4 then
				local vector = (target.Position - entity.Position):Normalized()

				-- Flies / spiders
				if entity.Variant == 0 then
					for i = -1, 1, 2 do
						local spawnVector = Vector.FromAngle(vector:GetAngleDegrees() + i * 20)

						-- Spiders
						if mod:IsRFChampion(entity, "Sloth") then
							EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + spawnVector * mod:Random(120, 160), false, -10)
						-- Attack flies
						else
							Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, entity.Position + vector * 20, spawnVector, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						end
					end

				-- Chargers
				elseif entity.Variant == 1 then
					local chargeVector = mod:ClampVector(vector, 90)

					local maggot = Isaac.Spawn(EntityType.ENTITY_CHARGER, 0, 0, entity.Position + chargeVector * 20, chargeVector, entity):ToNPC()
					maggot.State = NpcState.STATE_ATTACK
					maggot.V1 = chargeVector
					mod:PlaySound(maggot, SoundEffect.SOUND_MAGGOTCHARGE)
				end

				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_2)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end


		-- Replace projectile attack for champion
		elseif entity.State == NpcState.STATE_ATTACK2 and mod:IsRFChampion(entity, "Sloth") then
			entity.State = NpcState.STATE_ATTACK3

		-- Champion attack
		elseif entity.State == NpcState.STATE_ATTACK3 then
			if sprite:GetFrame() == 4 then
				local params = ProjectileParams()
				params.Color = mod.Colors.Tar
				params.Scale = 1.1

				local projectiles = entity:FireBossProjectilesEx(10, target.Position, 8, params)
				for i, projectile in pairs(projectiles) do
					projectile:GetData().DankSlothCreepShot = true
				end

				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_4)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end
		end


		-- Fix champion blood color
		if entity:IsDead() and mod:IsRFChampion(entity, "Sloth") then
			entity.SplatColor = mod.Colors.Tar
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.SlothUpdate, EntityType.ENTITY_SLOTH)

function mod:SlothCollision(entity, target, bool)
	if target.SpawnerType == EntityType.ENTITY_SLOTH then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.SlothCollision, EntityType.ENTITY_SLOTH)

-- Don't take damage from non-player explosions
function mod:SlothDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if mod:CheckValidMiniboss(entity) and damageSource.SpawnerType ~= EntityType.ENTITY_PLAYER and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0)
	and Isaac.GetChallenge() ~= Challenge.CHALLENGE_HOT_POTATO then -- HOT POTATO EXPLOSIONS DOESN'T COUNT AS PLAYER EXPLOSIONS FUCK THIS GAME
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.SlothDMG, EntityType.ENTITY_SLOTH)



-- Champion Sloth creep projectile
function mod:ChampionSlothCreepProjectile(projectile)
	if projectile:GetData().DankSlothCreepShot and projectile:IsDead() then
		mod:QuickCreep(EffectVariant.CREEP_BLACK, projectile.SpawnerEntity, projectile.Position, 1.25, 240)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.ChampionSlothCreepProjectile, ProjectileVariant.PROJECTILE_NORMAL)



function mod:ChampionSlothReward(pickup)
	if mod:CheckMinibossDropReplacement(pickup, EntityType.ENTITY_SLOTH, "Sloth") then
		-- Ball of Tar
		if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and pickup.SubType ~= CollectibleType.COLLECTIBLE_BALL_OF_TAR then
			pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_BALL_OF_TAR, false, true, false)

		-- Pills
		elseif pickup.Variant == PickupVariant.PICKUP_TAROTCARD then
			pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, 0, false, true, false)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.ChampionSlothReward)