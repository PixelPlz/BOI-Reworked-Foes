local mod = ReworkedFoes



function mod:SlothUpdate(entity)
	if mod:CheckValidMiniboss(entity) == true then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()

		-- Replace default attacks
		if entity.State == NpcState.STATE_ATTACK or entity.State == NpcState.STATE_ATTACK2 then
			entity.State = entity.State + 2


		-- Spawn
		elseif entity.State == NpcState.STATE_ATTACK3 then
			if sprite:GetFrame() == 4 then
				local vector = (target.Position - entity.Position):Normalized()

				-- Flies / spiders
				if entity.Variant == 0 then
					for i = -1, 1, 2 do
						local spawnVector = Vector.FromAngle(vector:GetAngleDegrees() + i * 15)

						-- Attack flies
						if entity.SubType == 0 then
							Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, entity.Position + vector * 20, spawnVector * 4, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						-- Spiders
						elseif entity.SubType == 1 then
							EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + spawnVector * mod:Random(120, 160), false, -10)
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


		-- Shoot
		elseif entity.State == NpcState.STATE_ATTACK4 then
			if sprite:GetFrame() == 4 then
				local params = ProjectileParams()

				-- White champion
				if entity.SubType == 1 then
					params.Color = mod.Colors.WhiteShot
					params.Scale = 1.1
					entity:FireBossProjectiles(9, target.Position, 7, params)

				-- Regular
				else
					params.FallingAccelModifier = 1.25
					params.FallingSpeedModifier = -20
					params.BulletFlags = ProjectileFlags.EXPLODE
					params.Color = mod.Colors.Ipecac
					params.Scale = 1.5
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(7), 0, params)
				end

				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_4)
			end

			if sprite:IsFinished() or (entity.Variant == 1 and entity.I1 == 0 and sprite:GetFrame() == 19) then
				-- Super Sloth shoots twice
				if entity.Variant == 1 and entity.I1 == 0 then
					sprite:Play("Attack", true)
					entity.I1 = entity.I1 + 1
					mod:FlipTowardsTarget(entity, sprite)

				else
					entity.State = NpcState.STATE_MOVE
					entity.I1 = 0
				end
			end
		end


		-- Champion blood color
		if entity:HasMortalDamage() and entity.SubType == 1 then
			entity.SplatColor = mod.Colors.WhiteShot
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

function mod:SlothDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.SpawnerType == EntityType.ENTITY_SLOTH and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.SlothDMG, EntityType.ENTITY_SLOTH)



-- Champion Sloth creep projectile
function mod:ChampionSlothCreepProjectile(projectile)
	if mod:CheckForRev() == false and projectile.SpawnerType == EntityType.ENTITY_SLOTH
	and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 1
	and projectile:IsDead() then
		mod:QuickCreep(EffectVariant.CREEP_WHITE, projectile.SpawnerEntity, projectile.Position, 1.25)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.ChampionSlothCreepProjectile, ProjectileVariant.PROJECTILE_NORMAL)



function mod:ChampionSlothReward(entity)
	if mod:CheckForRev() == false and entity.SpawnerType == EntityType.ENTITY_SLOTH and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 then
		-- Spider Bite
		if entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity.SubType ~= CollectibleType.COLLECTIBLE_SPIDER_BITE then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_SPIDER_BITE, false, true, false)

		-- Pills
		elseif entity.Variant == PickupVariant.PICKUP_TAROTCARD then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, 0, false, true, false)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.ChampionSlothReward)