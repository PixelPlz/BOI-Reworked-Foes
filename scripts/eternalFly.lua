local mod = BetterMonsters
local game = Game()


function mod:eternalFlyInit(npc)
	local data = npc:GetData()
	if npc.Type == EntityType.ENTITY_ETERNALFLY then
		data.isEternalFly = true
	end
	
	if FiendFolio then
		if npc.Type == FiendFolio.FF.DeadFlyOrbital.ID and npc.Variant == FiendFolio.FF.DeadFlyOrbital.Var then
			data.isEternalFly = true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.eternalFlyInit)


function mod:eternalFlyUpdate(npc)
	local data = npc:GetData()
	if data.isEternalFly and npc.Variant ~= 4040 then
		npc:Morph(EntityType.ENTITY_ATTACKFLY, 4040, 0, npc:GetChampionColorIdx())
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.eternalFlyUpdate, EntityType.ENTITY_ATTACKFLY)