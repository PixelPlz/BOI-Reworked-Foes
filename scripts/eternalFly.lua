local mod = BetterMonsters
local game = Game()



function mod:eternalFlyInit(entity)
	if entity.Type == EntityType.ENTITY_ETERNALFLY or (FiendFolio and entity.Type == FiendFolio.FF.DeadFlyOrbital.ID and entity.Variant == FiendFolio.FF.DeadFlyOrbital.Var) then
		entity:GetData().isEternalFly = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.eternalFlyInit)

function mod:eternalFlyUpdate(entity)
	if IRFconfig.classicEternalFlies == true and entity:GetData().isEternalFly and entity.Variant ~= 4040 then
		entity:Morph(EntityType.ENTITY_ATTACKFLY, 4040, 0, entity:GetChampionColorIdx())
		entity.HitPoints = entity.MaxHitPoints
		entity.I1 = 0
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.eternalFlyUpdate, EntityType.ENTITY_ATTACKFLY)