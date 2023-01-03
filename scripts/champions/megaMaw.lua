local mod = BetterMonsters



function mod:megaMawUpdate(entity)
	if entity.SubType == 1 then
		local sprite = entity:GetSprite()

		if sprite:IsFinished("FireRing") then
			entity.ProjectileCooldown = 30
		end
		
		if entity.ProjectileCooldown > 0 then
			entity.State = NpcState.STATE_IDLE
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end
		
		if sprite:IsEventTriggered("Shoot") then
			entity:PlaySound(SoundEffect.SOUND_GHOST_SHOOT, 1.25, 0, false, 1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.megaMawUpdate, EntityType.ENTITY_MEGA_MAW)

function mod:gateUpdate(entity)
	if entity.SubType == 1 and entity:GetSprite():IsEventTriggered("Shoot") then
		entity:PlaySound(SoundEffect.SOUND_GHOST_SHOOT, 1.25, 0, false, 1)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gateUpdate, EntityType.ENTITY_GATE)