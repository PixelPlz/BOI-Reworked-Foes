local mod = ReworkedFoes



function mod:GluttonyInit(entity)
	if mod:CheckValidMiniboss(entity) and mod:IsRFChampion(entity, "Gluttony") then
		entity.SplatColor = mod.Colors.GreenBlood

	-- Replace Gluttony worm with regular one
	elseif entity.Variant == 22 then
		--entity:Morph(EntityType.ENTITY_VIS, 22, 0, entity:GetChampionColorIdx())
		mod:ChubberWormInit(entity)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.GluttonyInit, EntityType.ENTITY_GLUTTONY)

function mod:GluttonyUpdate(entity)
	if mod:CheckValidMiniboss(entity) then
		local sprite = entity:GetSprite()

		-- Replace default projectile attack
		if entity.State == NpcState.STATE_ATTACK then
			-- The champion version should only do it if there are less than 3 maggots in the room
			if mod:IsRFChampion(entity, "Gluttony") and Isaac.CountEntities(nil, EntityType.ENTITY_MAGGOT, -1, -1) >= 3 then
				entity.State = NpcState.STATE_MOVE
			else
				entity.State = NpcState.STATE_ATTACK4
				sprite:Play("FatAttack", true)
			end

		-- Custom projectile attack
		elseif entity.State == NpcState.STATE_ATTACK4 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				-- Champion
				if mod:IsRFChampion(entity, "Gluttony") then
					local dir = mod:ClampVector((entity:GetPlayerTarget().Position - entity.Position):Normalized(), 90)
					local pos = entity.Position + dir:Resized(30)
					Isaac.Spawn(EntityType.ENTITY_MAGGOT, 0, 0, pos, Vector.Zero, entity)
					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)

				-- Regular / Super
				else
					entity:FireProjectiles(entity.Position, Vector(11, 0), 8, ProjectileParams())
					mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 1.1)

					-- Super
					if entity.Variant == 1 then
						local params = ProjectileParams()
						params.BulletFlags = ProjectileFlags.EXPLODE
						params.Scale = 1.65
						params.FallingAccelModifier = 1.1
						params.FallingSpeedModifier = -15

						for i = 0, 1 do
							entity:FireProjectiles(entity.Position, mod:RandomVector(6), 0, params)
						end
					end
				end

				-- Effects
				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):GetSprite()
				effect.Scale = entity.Scale * Vector(0.65, 0.65)
				effect.Offset = entity.Scale * Vector(3, -18 - (entity.Variant * 4))
				effect.Color = entity.SplatColor
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end


		-- Replace laser attack for champion
		elseif entity.State == NpcState.STATE_ATTACK2 and entity.SubType == 1 then
			entity.State = NpcState.STATE_ATTACK3

		-- Chubber attack
		elseif entity.State == NpcState.STATE_ATTACK3 and (sprite:IsEventTriggered("Shoot") or sprite:IsEventTriggered("Sound")) then
			mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS)

			if sprite:IsEventTriggered("Shoot") then
				-- Chubber worms
				for i = -1, 1, 2 do
					-- Get the velocity
					local speed = 21
					if entity.V1.Y ~= 0 then
						speed = 15
					end

					local vector = entity.V1:Rotated(30 * i):Resized(speed)
					Isaac.Spawn(EntityType.ENTITY_VIS, 22, 0, entity.Position, vector, entity).Parent = entity
				end

				-- Effects
				mod:PlaySound(nil, SoundEffect.SOUND_MEATHEADSHOOT, 1.1)
				mod:ShootEffect(entity, 2, Vector(0, -14), entity.SplatColor, 0.8, true)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GluttonyUpdate, EntityType.ENTITY_GLUTTONY)

function mod:GluttonyDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.SpawnerType == EntityType.ENTITY_GLUTTONY and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.GluttonyDMG, EntityType.ENTITY_GLUTTONY)



function mod:ChampionGluttonyReward(pickup)
	if mod:CheckMinibossDropReplacement(pickup, EntityType.ENTITY_GLUTTONY, "Gluttony") then
		-- Infestation
		if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and pickup.SubType ~= CollectibleType.COLLECTIBLE_INFESTATION then
			pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_INFESTATION, false, true, false)

		-- Rotten hearts
		elseif pickup.Variant == PickupVariant.PICKUP_HEART and pickup.SubType >= HeartSubType.HEART_SOUL and pickup.SubType ~= HeartSubType.HEART_ROTTEN then
			pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_ROTTEN, false, true, false)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.ChampionGluttonyReward)