local mod = BetterMonsters
local game = Game()



function mod:holyLeechInit(entity)
	if (entity.Variant == 0 and entity.SubType == 442) or entity.Variant == 2 then
		local fly = Isaac.Spawn(EntityType.ENTITY_ETERNALFLY, 0, 0, entity.Position, Vector.Zero, nil)
		fly.Parent = entity
		entity.Child = fly
		
		if entity.Variant == 2 then
			entity:Morph(EntityType.ENTITY_LEECH, 0, 442, entity:GetChampionColorIdx())
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.holyLeechInit, EntityType.ENTITY_LEECH)

function mod:holyLeechUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 442 then
		entity.Child.Velocity = entity.Velocity -- Makes the eternal fly able to keep up with the leech
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.holyLeechUpdate, EntityType.ENTITY_LEECH)

function mod:holyLeechDeath(entity)
	if entity.Variant == 0 and entity.SubType == 442 then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, entity:GetPlayerTarget().Position, Vector.Zero, entity):GetSprite().PlaybackSpeed = 1.25
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.holyLeechDeath, EntityType.ENTITY_LEECH)