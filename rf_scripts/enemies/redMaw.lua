local mod = ReworkedFoes

local Settings = {
	CloseDistance = 120,
	DetonateDelay = 45,
}



function mod:RedMawUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()

		-- Chasing
		if entity.State == NpcState.STATE_MOVE then
			-- Get the animation to play (I know this sucks, but I don't care)
			if entity.I1 >= Settings.DetonateDelay / 3 * 2 then
				mod:LoopingAnim(sprite, "Almost")
			elseif entity.I1 >= Settings.DetonateDelay / 3 then
				mod:LoopingAnim(sprite, "GettingThere")
			else
				mod:LoopingAnim(sprite, "Idle")
			end


			-- Swell up if close enough to the target / feared / randomly if confused
			if entity.Position:Distance(entity:GetPlayerTarget().Position) <= Settings.CloseDistance
			or mod:IsFeared(entity) or (mod:IsConfused(entity) and mod:Random(1) == 1) then
				entity.I1 = entity.I1 + 1

				-- Detonate
				if entity.I1 >= Settings.DetonateDelay then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Death", true)
					entity.I2 = 1
				end

			-- Reset the timer otherwise
			elseif entity.I1 > 0 then
				entity.I1 = entity.I1 - 1
			end


		-- Detonating
		elseif entity.State == NpcState.STATE_ATTACK and sprite:IsEventTriggered("Detonate") then
			entity:TakeDamage(entity.MaxHitPoints + entity.HitPoints, 0, EntityRef(entity), 0)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.RedMawUpdate, EntityType.ENTITY_MAW)

-- Detonation shots
function mod:RedMawDeath(entity)
	if entity.Variant == 1 and entity.I2 >= 1 then
		-- Circle of shots
		entity:FireProjectiles(entity.Position, Vector(8, 4), 7, ProjectileParams())

		-- + shots
		local params = ProjectileParams()
		params.Scale = 1.35
		entity:FireProjectiles(entity.Position, Vector(4, 4), 6, params)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.RedMawDeath, EntityType.ENTITY_MAW)