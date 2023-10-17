local mod = ReworkedFoes



function mod:GiantSpikeInit(entity)
	if entity.Variant == mod.Entities.GiantSpike then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)

		entity.State = NpcState.STATE_IDLE
		entity:GetSprite():Play("Appear", true)

		entity.I1 = 15 -- Delay before popping out
		entity.I2 = 15 -- Time to wait after popping out

		if mod:Random(1) == 1 then
			entity:GetSprite().FlipX = true
		end

		-- Destroy any obstacles under the spike
		local room = Game():GetRoom()
		room:DestroyGrid(room:GetGridIndex(entity.Position), true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.GiantSpikeInit, mod.Entities.Type)

function mod:GiantSpikeUpdate(entity)
	if entity.Variant == mod.Entities.GiantSpike then
		local sprite = entity:GetSprite()
		local target = nil


		-- Follow target if it's set
		if entity.Parent then
			target = entity.Parent

			entity.Position = target.Position
			entity.Velocity = target.Velocity
			entity.DepthOffset = target.DepthOffset + 10

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
					if target then
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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GiantSpikeUpdate, mod.Entities.Type)

function mod:GiantSpikeCollision(entity, target, bool)
	if entity.Variant == mod.Entities.GiantSpike and entity.Parent and target.Index == entity.Parent.Index then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.GiantSpikeCollision, mod.Entities.Type)