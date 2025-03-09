local mod = ReworkedFoes



function mod:HushUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()

	if not data.hushFix then
		entity:GetData().hushFix = {
			lastState = 0,
			animation = "Idle"
		}
	end


	-- Chill state
	if entity.State == 80085 then
		if sprite:IsFinished(data.hushFix.animation) then
			if (string.match(data.hushFix.animation, "FaceVanish")) then
				data.hushFix.animation = "FaceAppearDown"
				sprite:Play(data.hushFix.animation, true)

			elseif data.hushFix.animation == "LaserLoop" then
				data.hushFix.animation = "LaserEnd"
				sprite:Play(data.hushFix.animation, true)

			else
				sprite:Play("Wiggle", true)
			end
		end

		if entity.StateFrame <= 0 then
			entity.State = NpcState.STATE_IDLE
		else
			entity.StateFrame = entity.StateFrame -1
		end


	-- Chill the fuck out
	elseif entity.State == NpcState.STATE_IDLE and data.hushFix.lastState ~= NpcState.STATE_IDLE
	and entity.HitPoints / math.max(entity.MaxHitPoints, 0.001) < 0.5
	and entity.HitPoints / math.max(entity.MaxHitPoints, 0.001) > 0.01 then
		entity.State = 80085
		entity.StateFrame = 45
		data.hushFix.animation = sprite:GetAnimation()
	end

	data.hushFix.lastState = entity.State
end

if not REPENTOGON and not REPENTANCE_PLUS then
	mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.HushUpdate, EntityType.ENTITY_HUSH)
end



-- Fix the laser not getting slowed
function mod:HushLaserUpdate(effect)
	local room = Game():GetRoom()

	if room:HasSlowDown() or room:GetBrokenWatchState() == 1 then
		local baseLength = 8.4
		local drowsyMult = 0.513

		local targetLength = baseLength * (effect.Target:ToPlayer().MoveSpeed or 1) * drowsyMult
		effect.Velocity = effect.Velocity:Resized(targetLength)
	end
end

if not REPENTOGON then
	mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.HushLaserUpdate, EffectVariant.HUSH_LASER)
end