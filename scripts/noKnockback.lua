local mod = BetterMonsters
local game = Game()



-- [[ Mom ]]--
function mod:momInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.momInit, EntityType.ENTITY_MOM)



-- [[ Gurglings ]]--
function mod:gurglingsUpdate(entity)
	if entity.State == NpcState.STATE_ATTACK then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	else
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gurglingsUpdate, EntityType.ENTITY_GURGLING)