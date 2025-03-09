local mod = ReworkedFoes



function mod:RaglingInit(entity)
	entity.SplatColor = mod.Colors.RagManBlood

	-- Rag Man's Ragling
	if entity.Variant == 1 then
		entity.MaxHitPoints = 25 -- Same as the HP for Ragman's head

		-- Inherit the rolling head's subtype
		if entity.SpawnerType == EntityType.ENTITY_RAG_MAN and entity.SpawnerVariant == 1 and entity.SpawnerEntity then
			entity:GetData().newHP = entity.SpawnerEntity.HitPoints
			entity.SubType = entity.SpawnerEntity.SubType
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.RaglingInit, EntityType.ENTITY_RAGLING)

function mod:RaglingUpdate(entity)
	local sprite = entity:GetSprite()

	mod:StopSlidingAfterHop(entity)


	-- Replace default attack
	if entity.State == NpcState.STATE_ATTACK then
		entity.State = NpcState.STATE_ATTACK2

	-- Custom attack
	elseif entity.State == NpcState.STATE_ATTACK2 then
		entity.Velocity = mod:StopLerp(entity.Velocity)
		entity.TargetPosition = entity.Position

		if sprite:IsEventTriggered("Shoot") then
			local params = ProjectileParams()

			-- Rotation direction
			if entity.I1 == 0 then
				params.BulletFlags = ProjectileFlags.ORBIT_CW
				entity.I1 = 1
			elseif entity.I1 == 1 then
				params.BulletFlags = ProjectileFlags.ORBIT_CCW
				entity.I1 = 0
			end
			params.TargetPosition = entity.Position

			-- Red champion ones don't have homing
			if entity.SubType == 1 then
				params.Color = mod.Colors.RagManPink
			else
				params.BulletFlags = params.BulletFlags + ProjectileFlags.SMART
			end

			entity:FireProjectiles(entity.Position, Vector(10 - entity.Variant, 3 - entity.Variant), 9, params)
			mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 0.9)
		end

		if sprite:IsFinished() then
			entity.State = NpcState.STATE_MOVE
		end
	end


	-- Rag Man's Ragling
	if entity.Variant == 1 then
		-- Inherit the rolling head's health properly
		local data = entity:GetData()

		if data.newHP then
			entity.HitPoints = math.min(data.newHP, entity.MaxHitPoints)
			data.newHP = nil
		end


		-- Fix dead Rag Man Raglings rendering above entities
		-- Rag state
		if entity.State == NpcState.STATE_SPECIAL then
			entity.SortingLayer = SortingLayer.SORTING_BACKGROUND

		-- Revive
		elseif entity.State == NpcState.STATE_APPEAR_CUSTOM then
			entity.SortingLayer = SortingLayer.SORTING_NORMAL
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.RaglingUpdate, EntityType.ENTITY_RAGLING)