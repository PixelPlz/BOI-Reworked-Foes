local mod = BetterMonsters



function mod:boneOrbitalInit(entity)
	if entity.Variant == IRFentities.BoneOrbital then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_BLOOD_SPLASH | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)

		-- Play random animation
		entity:GetSprite():Play("Idle" .. math.random(0, 7), true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.boneOrbitalInit, IRFentities.Type)

function mod:boneOrbitalUpdate(entity)
	if entity.Variant == IRFentities.BoneOrbital then
		if mod:OrbitParent(entity, entity.Parent, 4, 30 - entity.SubType * 12) == false then
			entity:Kill()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.boneOrbitalUpdate, IRFentities.Type)