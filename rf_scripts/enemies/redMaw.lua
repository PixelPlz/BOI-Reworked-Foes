local mod = ReworkedFoes



function mod:RedMawUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()

		-- Primed
		if entity.State == NpcState.STATE_ATTACK then
			if sprite:GetFrame() >= 4 then
				entity:TakeDamage(entity.MaxHitPoints * 2, 0, EntityRef(entity), 0)
			end

		-- Prime if close enough
		elseif entity.Position:Distance(entity:GetPlayerTarget().Position) <= 100 then
			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Shoot", true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.RedMawUpdate, EntityType.ENTITY_MAW)

function mod:RedMawDeath(entity)
	if entity.Variant == 1 and entity.State == NpcState.STATE_ATTACK then
		entity:FireProjectiles(entity.Position, Vector(7.5, 4), 7, ProjectileParams())

		local params = ProjectileParams()
		params.Scale = 1.35
		entity:FireProjectiles(entity.Position, Vector(4, 4), 7, params)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.RedMawDeath, EntityType.ENTITY_MAW)