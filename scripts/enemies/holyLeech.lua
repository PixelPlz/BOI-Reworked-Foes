local mod = BetterMonsters



function mod:holyLeechUpdate(entity)
	if entity.Variant == 2 then
		-- Find the corresponding eternal fly
		if not entity.Child then
			for i, fly in pairs(Isaac.FindByType(EntityType.ENTITY_ETERNALFLY, -1, -1, false, false)) do
				if fly.SpawnerEntity and fly.SpawnerEntity.Index == entity.Index then
					fly.Parent = entity
					entity.Child = fly
				end
			end

		-- Makes the eternal fly able to keep up with the leech
		else
			entity.Child.Velocity = entity.Velocity
		end


		-- Death animation
		if entity:HasMortalDamage() then
			entity:GetSprite():Play("Death", true)
			entity.State = NpcState.STATE_DEATH
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.holyLeechUpdate, EntityType.ENTITY_LEECH)

function mod:holyLeechRender(entity, offset)
	if entity.Variant == 2 and entity:GetSprite():IsEventTriggered("Spawn") and entity.I2 == 0 then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, entity:GetPlayerTarget().Position, Vector.Zero, entity)
		SFXManager():Play(SoundEffect.SOUND_LASERRING_WEAK, 0.8, 0, false, 0.8)
		entity.I2 = 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.holyLeechRender, EntityType.ENTITY_LEECH)

function mod:holyLeechDeath(entity, target, bool)
	if entity.Variant == 2 then
		if entity.I2 == 0 then
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, entity:GetPlayerTarget().Position, Vector.Zero, entity)
			SFXManager():Play(SoundEffect.SOUND_LASERRING_WEAK, 0.8, 0, false, 0.8)
		else
			entity:BloodExplode()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.holyLeechDeath, EntityType.ENTITY_LEECH)