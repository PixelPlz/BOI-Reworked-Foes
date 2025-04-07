local mod = ReworkedFoes



function mod:EyeUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.State == NpcState.STATE_ATTACK then
		-- Give them a cooldown
		if (entity.Variant == 0 and sprite:GetFrame() == 19) -- Regular eye
		or (entity.Variant == 1 and sprite:GetOverlayFrame() == 19) then -- Bloodshot eye
			entity.ProjectileCooldown = (entity.Variant + 1) * 15
		end

		-- Prevent them from shooting if they're on cooldown
		if entity.ProjectileCooldown > 0 then
			-- Regular eye
			if entity.Variant == 0 then
				sprite:Stop()
				entity.State = NpcState.STATE_IDLE

			-- Bloodshot eye
			elseif entity.Variant == 1 then
				sprite:SetOverlayFrame("ShootOverlay", 0)
			end
		end


		-- Tracer
		if not entity:GetData().IndicatorBrim
		and ((entity.Variant == 0 and sprite:GetFrame() == 1) -- Regular eye
		or (entity.Variant == 1 and sprite:GetOverlayFrame() == 1)) then -- Bloodshot eye
			local pitch = 1.1
			local xScale = 1
			local offset = 20

			if entity.Variant == 1 then
				pitch = 1
				xScale = 3
				offset = 10
			end

			mod:PlaySound(nil, SoundEffect.SOUND_LASERRING_WEAK, 1, pitch)
			mod:QuickTracer(entity, entity.V1.X, Vector.FromAngle(entity.V1.X):Resized(offset) + Vector(0, entity.Variant * -18), 6, xScale)
		end


	-- Cooldown
	elseif entity.ProjectileCooldown > 0 then
		entity.ProjectileCooldown = entity.ProjectileCooldown - 1
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.EyeUpdate, EntityType.ENTITY_EYE)