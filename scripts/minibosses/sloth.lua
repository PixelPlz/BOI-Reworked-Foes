local mod = BetterMonsters

local Settings = {
	SuperSlothShots = 2,
	ShotSpeed = 7,
	FlyAngle = 15,
	FlySpeed = 8,
	SpiderCount = 5
}



function mod:slothUpdate(entity)
	if mod:CheckForRev() == false and ((entity.Variant == 0 and entity.SubType <= 1) or entity.Variant == 1) then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()

		-- Custom attacks
		if entity.State == NpcState.STATE_ATTACK or entity.State == NpcState.STATE_ATTACK2 then
			entity.State = entity.State + 2

		elseif entity.State == NpcState.STATE_ATTACK3 or entity.State == NpcState.STATE_ATTACK4 then
			if sprite:GetFrame() == 4 then
				local vector = (target.Position - entity.Position)
				
				-- Spawn
				if entity.State == NpcState.STATE_ATTACK3 then
					entity:PlaySound(SoundEffect.SOUND_MONSTER_GRUNT_2, 1, 0, false, 1)

					-- Flies / spiders
					if entity.Variant == 0 then
						for i = -1, 1, 2 do
							local flyVector = Vector.FromAngle(vector:GetAngleDegrees() + i * Settings.FlyAngle)
							
							if entity.SubType == 0 then
								Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, entity.Position + (vector:Normalized() * 20), flyVector * Settings.FlySpeed, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
							elseif entity.SubType == 1 then
								EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + (flyVector * math.random(120, 160)), false, -10)
							end
						end

					-- Chargers
					elseif entity.Variant == 1 then
						local chargeVector = Vector.Zero
						if vector:GetAngleDegrees() > -45 and vector:GetAngleDegrees() < 45 then
							chargeVector = Vector(1, 0)
						elseif vector:GetAngleDegrees() >= 45 and vector:GetAngleDegrees() <= 135 then
							chargeVector = Vector(0, 1)
						elseif vector:GetAngleDegrees() < -45 and vector:GetAngleDegrees() > -135 then
							chargeVector = Vector(0, -1)
						else
							chargeVector = Vector(-1, 0)
						end

						local maggot = Isaac.Spawn(EntityType.ENTITY_CHARGER, 0, 0, entity.Position + (chargeVector * 20), chargeVector, entity):ToNPC()
						maggot.State = NpcState.STATE_ATTACK
						maggot.V1 = chargeVector
						maggot:PlaySound(SoundEffect.SOUND_MAGGOTCHARGE, 1, 0, false, 1)
					end


				-- Shoot
				elseif entity.State == NpcState.STATE_ATTACK4 then
					entity:PlaySound(SoundEffect.SOUND_MONSTER_GRUNT_4, 1, 0, false, 1)

					local params = ProjectileParams()
					if entity.SubType == 0 then
						params.FallingAccelModifier = 1.25
						params.FallingSpeedModifier = -20
						params.BulletFlags = ProjectileFlags.EXPLODE
						params.Color = greenBulletColor
						params.Scale = 1.5
						entity:FireProjectiles(entity.Position, vector:Normalized() * Settings.ShotSpeed, 0, params)
					
					elseif entity.SubType == 1 then
						params.Color = skyBulletColor
						params.FallingAccelModifier = 0.5
						params.Scale = 1.1
						params.VelocityMulti = 1.1
						entity:FireBossProjectiles(8, target.Position, 4, params)
					end
				end
			end


			-- Super Sloth shoots 2 times
			if sprite:IsFinished("Attack") or (entity.Variant == 1 and sprite:GetFrame() == 18 and entity.I2 < Settings.SuperSlothShots - 1 and entity.State == NpcState.STATE_ATTACK4) then
				entity.I2 = entity.I2 + 1

				if entity.Variant == 0 or entity.State == NpcState.STATE_ATTACK3 or entity.I2 >= Settings.SuperSlothShots then
					entity.I2 = 0
					entity.State = NpcState.STATE_MOVE

				else
					sprite:Play("Attack", true)
					if target.Position.X < entity.Position.X then
						sprite.FlipX = true
					else
						sprite.FlipX = false
					end
				end
			end
		end


		if entity.SubType == 1 and entity:HasMortalDamage() then
			entity.SplatColor = skyBulletColor
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.slothUpdate, EntityType.ENTITY_SLOTH)

function mod:slothCollision(entity, target, cock)
	if target.SpawnerType == EntityType.ENTITY_SLOTH then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.slothCollision, EntityType.ENTITY_SLOTH)

function mod:slothDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.SpawnerType == EntityType.ENTITY_SLOTH and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.slothDMG, EntityType.ENTITY_SLOTH)

function mod:slothProjectileUpdate(projectile)
	if mod:CheckForRev() == false and projectile.SpawnerType == EntityType.ENTITY_SLOTH and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 1 and projectile:IsDead() then
		mod:QuickCreep(EffectVariant.CREEP_WHITE, projectile.SpawnerEntity, projectile.Position, 1.25)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.slothProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)



function mod:championSlothReward(entity)
	if mod:CheckForRev() == false and entity.SpawnerType == EntityType.ENTITY_SLOTH and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 then
		-- Spider Bite
		if entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity.SubType ~= 89 then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 89, false, true, false)
		
		-- Pills
		elseif entity.Variant == PickupVariant.PICKUP_TAROTCARD then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, 0, false, true, false)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.championSlothReward)