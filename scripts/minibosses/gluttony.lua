local mod = BetterMonsters



function mod:gluttonyInit(entity)
	if entity.Variant == 0 and entity.SubType == 1 then
		entity.SplatColor = Color(0.4,0.8,0.4, 1, 0,0.4,0)
	
	-- Replace Gluttony worm with regular one
	elseif entity.Variant == 22 then
		entity.Mass = 0.1
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		entity:Morph(EntityType.ENTITY_VIS, 22, 0, entity:GetChampionColorIdx())
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.gluttonyInit, EntityType.ENTITY_GLUTTONY)

function mod:gluttonyUpdate(entity)
	if mod:CheckForRev() == false and ((entity.Variant == 0 and entity.SubType <= 1) or entity.Variant == 1) then
		local sprite = entity:GetSprite()


		-- Custom fat attack for super gluttony
		if (entity.Variant == 1 or entity.SubType == 1) and entity.State == NpcState.STATE_ATTACK then
			entity.State = NpcState.STATE_ATTACK4
			sprite:Play("FatAttack", true)
		end

		-- Custom attack for champion gluttony
		if entity.SubType == 1 and entity.State == NpcState.STATE_ATTACK2 then
			entity.State = NpcState.STATE_ATTACK3
		end

		if (entity.State == NpcState.STATE_ATTACK4 and sprite:IsFinished("FatAttack")) or (entity.State == NpcState.STATE_ATTACK5 and sprite:IsFinished(sprite:GetAnimation())) then
			entity.State = NpcState.STATE_MOVE
		end


		if sprite:IsEventTriggered("Shoot") or (entity.SubType == 1 and sprite:GetFrame() == 72) then
			-- Fat attack
			if entity.State == NpcState.STATE_ATTACK or entity.State == NpcState.STATE_ATTACK4 then
				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):GetSprite()
				effect.Scale = Vector(entity.Scale * 0.6, entity.Scale * 0.6)
				effect.Offset = Vector(entity.Scale * 3, entity.Scale * (-18 - (entity.Variant * 4)))
				effect.Color = entity.SplatColor


				if entity.State == NpcState.STATE_ATTACK4 then
					-- Super Gluttony
					if entity.Variant == 1 then
						local params = ProjectileParams()
						entity:FireProjectiles(entity.Position, Vector(11, 0), 8, params)

						params.BulletFlags = (ProjectileFlags.ACID_RED | ProjectileFlags.EXPLODE)
						params.Scale = 1.65
						params.FallingAccelModifier = 1.25
						params.FallingSpeedModifier = math.random(-20, -10)
						
						for i = 0, 1 do
							entity:FireProjectiles(entity.Position, Vector.FromAngle(math.random(0, 359)) * 7, 0, params)
						end
						entity:PlaySound(SoundEffect.SOUND_BLOODSHOOT, 1.1, 0, false, 1)

					-- Champion Gluttony
					elseif entity.SubType == 1 then
						Isaac.Spawn(EntityType.ENTITY_MAGGOT, 0, 0, entity.Position + Vector(0, 5), Vector.Zero, entity)
						SFXManager():Play(SoundEffect.SOUND_SUMMONSOUND)
					end
				end


			-- Chubber attack for champion gluttony
			elseif entity.State == NpcState.STATE_ATTACK3 then
				entity:PlaySound(SoundEffect.SOUND_MEAT_JUMPS, 1, 0, false, 1)
					
				-- Blood effect
				if sprite:IsEventTriggered("Shoot") then
					entity:PlaySound(SoundEffect.SOUND_MEATHEADSHOOT, 1.1, 0, false, 1)
					mod:shootEffect(entity, 2, Vector(0, -14), entity.SplatColor, entity.Scale * 0.8, true)
					
					for i = -1, 1, 2 do
						local speed = 20
						if entity.V1.Y ~= 0 then
							speed = 14
						end
						Isaac.Spawn(EntityType.ENTITY_VIS, 22, 0, entity.Position, Vector.FromAngle(entity.V1:GetAngleDegrees() + (30 * i)) * speed, entity).Parent = entity
					end
				end
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
		if entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity.SubType ~= 148 then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 148, false, true, false)
		
		-- Rotten hearts
		elseif entity.Variant == PickupVariant.PICKUP_HEART and entity.SubType >= HeartSubType.HEART_SOUL and entity.SubType ~= HeartSubType.HEART_ROTTEN then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_ROTTEN, false, true, false)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.championGluttonyReward)