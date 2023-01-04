local mod = BetterMonsters



-- [[ Poky / Slide ]]--
function mod:pokyInit(entity)
	if entity.Variant == 1 then
		entity.Mass = 1000
	else
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.pokyInit, EntityType.ENTITY_POKY)

function mod:pokyUpdate(entity)
	if entity.State == NpcState.STATE_SPECIAL then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		if entity.StateFrame >= 30 then
			entity:Kill()
		else
			entity.StateFrame = entity.StateFrame + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.pokyUpdate, EntityType.ENTITY_POKY)



-- [[ Wall huggers ]]--
function mod:wallHuggerInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.wallHuggerInit, EntityType.ENTITY_WALL_HUGGER)

function mod:wallHuggerUpdate(entity)
	if entity:GetSprite():GetAnimation() == "No-Spikes" and entity.FrameCount > 30 then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		if entity.StateFrame >= 30 then
			entity:Kill()
		else
			entity.StateFrame = entity.StateFrame + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.wallHuggerUpdate, EntityType.ENTITY_WALL_HUGGER)



-- [[ Grudge ]]--
function mod:grudgeUpdate(entity)
	if entity.State == NpcState.STATE_SPECIAL and entity.Variant == 0 then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		if entity.StateFrame >= 30 then
			entity:Kill()
		else
			entity.StateFrame = entity.StateFrame + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.grudgeUpdate, EntityType.ENTITY_GRUDGE)