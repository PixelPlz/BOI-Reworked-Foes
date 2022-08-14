local mod = BetterMonsters
local game = Game()



function mod:holyLeechUpdate(entity)
	if entity.Variant == 2 then
		for i, fly in pairs(Isaac.FindByType(EntityType.ENTITY_ETERNALFLY, -1, -1, false, false)) do
			if fly.SpawnerEntity and fly.SpawnerEntity.Index == entity.Index then
				fly.Parent = entity
				entity.Child = fly
			end
		end

		if entity.Child then
			entity.Child.Velocity = entity.Velocity -- Makes the eternal fly able to keep up with the leech
		end
		
		if entity:IsDead() then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.holyLeechUpdate, EntityType.ENTITY_LEECH)

function mod:holyLeechDeath(entity)
	if entity.Variant == 2 then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, entity:GetPlayerTarget().Position, Vector.Zero, entity):GetSprite().PlaybackSpeed = 1.25
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.holyLeechDeath, EntityType.ENTITY_LEECH)