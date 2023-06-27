local mod = BetterMonsters



function mod:giantSpikeInit(entity)
	if entity.Variant == IRFentities.GiantSpike then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

		entity.State = NpcState.STATE_IDLE
		entity:GetSprite():Play("Appear", true)

		entity.I1 = 20
		entity.I2 = 10

		if mod:Random(1) == 1 then
			entity:GetSprite().FlipX = true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.giantSpikeInit, IRFentities.Type)

function mod:giantSpikeUpdate(entity)
	if entity.Variant == IRFentities.GiantSpike then
		local sprite = entity:GetSprite()

		-- Follow target if it's set
		if entity.Target then
			entity.Position = entity.Target.Position
			entity.Velocity = entity.Target.Velocity
			entity.DepthOffset = entity.Target.DepthOffset + 10
		else
			entity.Velocity = Vector.Zero
		end

		-- Don't get knocked back
		if entity:HasEntityFlags(EntityFlag.FLAG_KNOCKED_BACK) then
			entity:ClearEntityFlags(EntityFlag.FLAG_KNOCKED_BACK)
		end


		-- Retracted
		if entity.State == NpcState.STATE_IDLE then
			-- Appear
			if entity.StateFrame == 0 then
				if sprite:IsEventTriggered("Sound") then
					for i = 1, 3 do
						local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 6, entity.Position, mod:RandomVector(3), entity):ToEffect()
						rocks:GetSprite():Play("rubble", true)
						rocks.State = 2
					end
					mod:PlaySound(nil, SoundEffect.SOUND_ROCK_CRUMBLE, 0.5)
				end

				if sprite:IsFinished() then
					entity.StateFrame = 1
				end

			-- Waiting
			elseif entity.StateFrame == 1 then
				mod:LoopingAnim(sprite, "IdleRetracted")

				if entity.I1 <= 0 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Extend", true)
					entity.StateFrame = 0

				else
					entity.I1 = entity.I1 - 1
				end
			end


		-- Extended
		elseif entity.State == NpcState.STATE_ATTACK then
			-- Extend
			if entity.StateFrame == 0 then
				if sprite:IsEventTriggered("Extend") then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

					-- Effects
					for i = 1, 6 do
						local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 6, entity.Position, mod:RandomVector(3), entity):ToEffect()
						rocks:GetSprite():Play("rubble", true)
						rocks.State = 2
					end
					mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_BURST_OUT, 0.75)

					-- Destroy any obstacles under the spike
					local room = Game():GetRoom()
					local gridEntity = room:GetGridEntityFromPos(entity.Position)

					if gridEntity ~= nil and (gridEntity.CollisionClass == GridCollisionClass.COLLISION_SOLID or gridEntity:GetType() == GridEntityType.GRID_SPIDERWEB) then
						gridEntity:Destroy(true)
					end

					-- Kill target
					if entity.Target then
						entity.Target:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
						entity.Target:Kill()

						local shooter = entity.Target
						if entity.SpawnerEntity then
							shooter = entity.SpawnerEntity
						end
						shooter:ToNPC():FireProjectiles(entity.Target.Position, Vector(8, 4), 6, ProjectileParams())

						entity.Target = nil
					end
				end

				if sprite:IsFinished() then
					entity.StateFrame = 1
					entity.CollisionDamage = 0
				end

			-- Waiting
			elseif entity.StateFrame == 1 then
				mod:LoopingAnim(sprite, "IdleExtended")

				if entity.I2 <= 0 then
					entity.State = NpcState.STATE_SUICIDE
					sprite:Play("Retract", true)
					entity.StateFrame = 0

				else
					entity.I2 = entity.I2 - 1
				end
			end


		-- Disappear
		elseif entity.State == NpcState.STATE_SUICIDE then
			if sprite:IsEventTriggered("Retract") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_ENTER_GROUND, 0.75)
			end

			if sprite:IsFinished() then
				entity:Remove()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.giantSpikeUpdate, IRFentities.Type)

function mod:giantSpikeDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == IRFentities.GiantSpike then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.giantSpikeDMG, IRFentities.Type)