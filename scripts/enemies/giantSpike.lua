local mod = BetterMonsters



function mod:giantSpikeInit(entity)
	if entity.Variant == IRFentities.GiantSpike then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)

		entity.State = NpcState.STATE_IDLE
		entity:GetSprite():Play("Appear", true)

		entity.I1 = 15
		entity.I2 = 15

		if mod:Random(1) == 1 then
			entity:GetSprite().FlipX = true
		end

		-- Destroy any obstacles under the spike
		local gridEntity = Game():GetRoom():GetGridEntityFromPos(entity.Position)
		if gridEntity ~= nil and (gridEntity.CollisionClass == GridCollisionClass.COLLISION_SOLID or gridEntity:GetType() == GridEntityType.GRID_SPIDERWEB) then
			gridEntity:Destroy(true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.giantSpikeInit, IRFentities.Type)

function mod:giantSpikeUpdate(entity)
	if entity.Variant == IRFentities.GiantSpike then
		local sprite = entity:GetSprite()
		local target = nil


		-- Follow target if it's set
		if entity.Target then
			if entity.SpawnerEntity and entity.Target.Index == entity.SpawnerEntity.Index then
				entity.Target = nil
			else
				target = entity.Target

				entity.Position = target.Position
				entity.Velocity = target.Velocity
				entity.DepthOffset = target.DepthOffset + 10
			end

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
					-- Effects
					for i = 1, 2 do
						local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 6, entity.Position, mod:RandomVector(2), entity):ToEffect()
						rocks:GetSprite():Play("rubble", true)
						rocks.State = 2
					end
					mod:PlaySound(nil, SoundEffect.SOUND_ROCK_CRUMBLE, 0.4)
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
			-- Make enemies go around them
			local room = Game():GetRoom()
			local gridIndex = room:GetGridIndex(entity.Position)
			room:SetGridPath(gridIndex, 900)

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
					mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_BURST_OUT, 0.6)

					-- Kill target
					if entity.Target then
						target:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
						target:TakeDamage(target.MaxHitPoints * 2, (DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_IGNORE_ARMOR), EntityRef(entity), 0)
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
				mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_ENTER_GROUND, 0.6)
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

function mod:giantSpikeCollide(entity, target, bool)
	if entity.Variant == IRFentities.GiantSpike and entity.Target and target.Index == entity.Target.Index then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.giantSpikeCollide, IRFentities.Type)