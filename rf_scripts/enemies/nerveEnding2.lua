local mod = ReworkedFoes

local Settings = {
	SideRange = 25,
	FrontRange = 100,
	Cooldown = 10,
	WhipStrength = 5
}



function mod:NerveEnding2Init(entity)
	if entity.Variant == 1 then
		entity.ProjectileCooldown = 20
		entity.TargetPosition = entity.Position
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.NerveEnding2Init, EntityType.ENTITY_NERVE_ENDING)

function mod:NerveEnding2Update(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()

		-- Stay in the same position
		entity.Position = mod:Lerp(entity.Position, entity.TargetPosition, 0.5)
		entity.Velocity = Vector.Zero


		-- Idle
		if entity.State == NpcState.STATE_IDLE then
			mod:LoopingAnim(sprite, "Idle")

			if entity.ProjectileCooldown <= 0 then
				-- Attack if in range
				local swingCheck = mod:CheckCardinalAlignment(entity, Settings.SideRange, Settings.FrontRange, 3)

				if swingCheck ~= false then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Swing" .. mod:GetDirectionString(swingCheck), true)
					entity.V1 = Vector(swingCheck, 0)
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Attack
		elseif entity.State == NpcState.STATE_ATTACK then
			-- Sound
			if sprite:IsEventTriggered("Sound") then
				mod:PlaySound(nil, SoundEffect.SOUND_WHIP)

			-- Check if it hit the target
			elseif sprite:IsEventTriggered("Hit") then
				local hurtCheck = mod:CheckCardinalAlignment(entity, Settings.SideRange, Settings.FrontRange, 3, 1, entity.V1.X)

				-- On succesful hit
				if hurtCheck ~= false then
					target:TakeDamage(2, 0, EntityRef(entity), 0)
					target.Velocity = target.Velocity + Vector.FromAngle(hurtCheck):Resized(Settings.WhipStrength)
					mod:PlaySound(nil, SoundEffect.SOUND_WHIP_HIT, 1, 1, 5)
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
				entity.ProjectileCooldown = Settings.Cooldown
			end
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.NerveEnding2Update, EntityType.ENTITY_NERVE_ENDING)