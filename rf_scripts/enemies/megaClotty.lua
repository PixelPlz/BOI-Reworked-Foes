local mod = ReworkedFoes



function mod:MegaClottyInit(entity)
	entity:SetSize(28, Vector(1, 0.75), 16)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MegaClottyInit, EntityType.ENTITY_MEGA_CLOTTY)

function mod:MegaClottyUpdate(entity)
	if not (Retribution and entity.Variant == 1873)
	and (entity.State == NpcState.STATE_ATTACK or entity.State == NpcState.STATE_ATTACK2) then
		local sprite = entity:GetSprite()

		-- Replace the default attack
		if entity.State == NpcState.STATE_ATTACK then
			entity.State = NpcState.STATE_ATTACK2
			sprite:Play("Attack", true)
		end


		-- New attack
		if entity.State == NpcState.STATE_ATTACK2 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Scale = 1.4

				-- Get the pattern to attack in
				local pattern = mod:Random(1, 8) -- No weighted outcome picker :-(
				local mode = 6

				-- I.Blob shots
				if pattern >= 7 then
					mode = 8
				-- Clot shots
				elseif pattern >= 4 then
					mode = 7
				end

				entity:FireProjectiles(entity.Position, Vector(10, 0), mode, params)


				-- Effects
				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.8)

				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity):GetSprite()
				effect.Scale = Vector.One * entity.Scale * 0.8
			end

			if sprite:GetFrame() >= 50 then
				entity.State = NpcState.STATE_MOVE
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.MegaClottyUpdate, EntityType.ENTITY_MEGA_CLOTTY)