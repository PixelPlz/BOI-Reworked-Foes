local mod = BetterMonsters



function mod:gluttonyInit(entity)
	if entity.Variant == 0 and entity.SubType == 1 then
		entity.SplatColor = IRFcolors.GreenBlood

	-- Replace Gluttony worm with regular one
	elseif entity.Variant == 22 then
		entity.Mass = 0.1
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		entity:Morph(EntityType.ENTITY_VIS, 22, 0, entity:GetChampionColorIdx())
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.gluttonyInit, EntityType.ENTITY_GLUTTONY)

function mod:gluttonyUpdate(entity)
	if mod:CheckValidMiniboss(entity) == true then
		local sprite = entity:GetSprite()

		-- Blood effect for projectile attack
		local function attackEffects()
			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):GetSprite()
			effect.Scale = entity.Scale * Vector(0.65, 0.65)
			effect.Offset = entity.Scale * Vector(3, -18 - (entity.Variant * 4))
			effect.Color = entity.SplatColor

			if entity.SubType ~= 1 then
				mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 1.1)
			end
		end


		if entity.State == NpcState.STATE_ATTACK then
			-- Replace projectile attack for champion and Super Gluttony
			if entity.Variant == 1 or entity.SubType == 1 then
				-- The champion version should only do it if there are less than 4 maggots in the room
				if entity.SubType == 1 and Isaac.CountEntities(nil, EntityType.ENTITY_MAGGOT, -1, -1) >= 4 then
					entity.State = NpcState.STATE_MOVE
				else
					entity.State = NpcState.STATE_ATTACK4
					sprite:Play("FatAttack", true)
				end

			-- Extra effects
			elseif sprite:IsEventTriggered("Shoot") then
				attackEffects()
			end


		-- Replace laser attack for champion
		elseif entity.State == NpcState.STATE_ATTACK2 and entity.SubType == 1 then
			entity.State = NpcState.STATE_ATTACK3


		-- Chubber attack for champion
		elseif entity.State == NpcState.STATE_ATTACK3 and (sprite:IsEventTriggered("Shoot") or sprite:GetFrame() == 72) then
			mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS)

			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(nil, SoundEffect.SOUND_MEATHEADSHOOT, 1.1)
				mod:ShootEffect(entity, 2, Vector(0, -14), entity.SplatColor, 0.8, true)

				-- Chubber worms
				for i = -1, 1, 2 do
					local speed = 21
					if entity.V1.Y ~= 0 then
						speed = 15
					end
					Isaac.Spawn(EntityType.ENTITY_VIS, 22, 0, entity.Position, Vector.FromAngle(entity.V1:GetAngleDegrees() + 30 * i):Resized(speed), entity).Parent = entity
				end
			end


		-- Custom projectile attack
		elseif entity.State == NpcState.STATE_ATTACK4 then
			if sprite:IsEventTriggered("Shoot") then
				attackEffects()

				-- Super Gluttony
				if entity.Variant == 1 then
					local params = ProjectileParams()
					entity:FireProjectiles(entity.Position, Vector(11, 0), 8, params)

					params.BulletFlags = (ProjectileFlags.ACID_RED | ProjectileFlags.EXPLODE)
					params.Scale = 1.65
					params.FallingAccelModifier = 1.1
					params.FallingSpeedModifier = mod:Random(10, 20) * -1

					for i = 0, 1 do
						entity:FireProjectiles(entity.Position, mod:RandomVector(7), 0, params)
					end

				-- Champion Gluttony
				elseif entity.SubType == 1 then
					Isaac.Spawn(EntityType.ENTITY_MAGGOT, 0, 0, entity.Position + Vector(0, 5), Vector.Zero, entity)
					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gluttonyUpdate, EntityType.ENTITY_GLUTTONY)

function mod:gluttonyDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.SpawnerType == EntityType.ENTITY_GLUTTONY and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.gluttonyDMG, EntityType.ENTITY_GLUTTONY)



function mod:championGluttonyReward(entity)
	if mod:CheckForRev() == false and entity.SpawnerType == EntityType.ENTITY_GLUTTONY and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 then
		-- Infestation
		if entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity.SubType ~= CollectibleType.COLLECTIBLE_INFESTATION then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_INFESTATION, false, true, false)
		
		-- Rotten hearts
		elseif entity.Variant == PickupVariant.PICKUP_HEART and entity.SubType >= HeartSubType.HEART_SOUL and entity.SubType ~= HeartSubType.HEART_ROTTEN then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_ROTTEN, false, true, false)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.championGluttonyReward)