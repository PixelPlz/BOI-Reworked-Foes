local mod = BetterMonsters



function mod:eyeUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.State == NpcState.STATE_ATTACK then
		-- Give them a cooldown
		if (entity.Variant == 0 and sprite:GetFrame() == 19) or (entity.Variant == 1 and sprite:GetOverlayFrame() == 19) then
			entity.ProjectileCooldown = (entity.Variant + 1) * 15
		end

		-- Prevent them from shooting if they're on cooldown
		if entity.ProjectileCooldown > 0 then
			if entity.Variant == 0 then
				sprite:Stop()
				entity.State = NpcState.STATE_IDLE
			elseif entity.Variant == 1 then
				sprite:SetOverlayFrame("ShootOverlay", 0)
			end
		end


		-- Tracer
		if not entity:GetData().IndicatorBrim and IRFConfig.laserEyes == true and ((entity.Variant == 0 and sprite:GetFrame() == 1) or (entity.Variant == 1 and sprite:GetOverlayFrame() == 1)) then
			local pitch = 1.1
			local xScale = 1
			local offset = 20

			if entity.Variant == 1 then
				pitch = 1
				xScale = 2
				offset = 10
			end

			mod:PlaySound(nil, SoundEffect.SOUND_LASERRING_WEAK, 1, pitch)
			mod:QuickTracer(entity, entity.V1.X, Vector.FromAngle(entity.V1.X):Resized(offset) + Vector(0, entity.Variant * -18), 15, 1, xScale)
		end


	-- Cooldown
	elseif entity.ProjectileCooldown > 0 then
		entity.ProjectileCooldown = entity.ProjectileCooldown - 1
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.eyeUpdate, EntityType.ENTITY_EYE)