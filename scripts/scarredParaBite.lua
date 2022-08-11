local mod = BetterMonsters
local game = Game()



function mod:scarredParaBiteUpdate(entity)
	if entity.Variant == 1 and entity:GetSprite():IsPlaying("DigIn") and entity:GetSprite():GetFrame() == 5 then
		entity:FireProjectiles(entity.Position, Vector(8, 0), 7, ProjectileParams())
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.scarredParaBiteUpdate, EntityType.ENTITY_PARA_BITE)