local mod = BetterMonsters
local game = Game()



--[[ Clotty ]]--
function mod:clottyUpdate(entity)
	if entity.Variant ~= 3 and entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() > 2 then
		entity.Velocity = Vector.Zero
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.clottyUpdate, EntityType.ENTITY_CLOTTY)

--[[ Cloggy ]]--
function mod:cloggyUpdate(entity)
	if entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() > 2 then
		entity.Velocity = Vector.Zero
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.cloggyUpdate, EntityType.ENTITY_CLOGGY)