local mod = BetterMonsters



function mod:camilloJrUpdate(entity)
	local sprite = entity:GetSprite()


	if sprite:IsPlaying("ShootDown") or sprite:IsPlaying("ShootUp") then
		-- Prevent them from shooting if they're on cooldown
		if entity.ProjectileCooldown > 0 and not sprite:WasEventTriggered("Shoot") then
			sprite:Play("FloatDown", true)


		-- Tracer
		elseif sprite:GetFrame() == 1 then
			mod:PlaySound(nil, SoundEffect.SOUND_LASERRING_WEAK, 1, 1.1)

			local angle = entity.TargetPosition:GetAngleDegrees()
			mod:QuickTracer(entity, angle, Vector.FromAngle(angle):Resized(20) + Vector(0, -25), 15, 1)
			entity.V2 = entity.TargetPosition


		-- Give them a cooldown
		elseif sprite:IsEventTriggered("Shoot") then
			entity.TargetPosition = entity.V2
			entity.ProjectileCooldown = 30
		end

	else
		entity.ProjectileCooldown = entity.ProjectileCooldown - 1
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.camilloJrUpdate, EntityType.ENTITY_CAMILLO_JR)