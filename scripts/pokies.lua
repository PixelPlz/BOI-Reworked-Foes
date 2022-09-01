local mod = BetterMonsters
local game = Game()



-- [[ Pokies ]]--
function mod:pokyUpdate(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

	if entity:GetSprite():GetAnimation() == "No-Spikes" then
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
function mod:wallHuggerUpdate(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

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
	if entity.State == 16 then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		if entity.StateFrame >= 30 then
			entity:Kill()
		else
			entity.StateFrame = entity.StateFrame + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.grudgeUpdate, EntityType.ENTITY_GRUDGE)