local mod = BetterMonsters



function mod:holyLeechUpdate(entity)
	-- Death animation
	if entity.Variant == 2 and entity:HasMortalDamage() then
		entity:GetSprite():Play("Death", true)
		entity.State = NpcState.STATE_DEATH
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.holyLeechUpdate, EntityType.ENTITY_LEECH)

function mod:holyLeechRender(entity, offset)
	-- Crack the sky beam
	if entity.Variant == 2 and entity:GetSprite():IsEventTriggered("Spawn") and entity.I2 == 0 then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, entity:GetPlayerTarget().Position, Vector.Zero, entity)
		mod:PlaySound(nil, SoundEffect.SOUND_LASERRING_WEAK, 0.8, 0.8)
		entity.I2 = 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.holyLeechRender, EntityType.ENTITY_LEECH)

function mod:holyLeechDeath(entity, target, bool)
	if entity.Variant == 2 then
		-- Failsafe
		if entity.I2 == 0 then
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, entity:GetPlayerTarget().Position, Vector.Zero, entity)
			mod:PlaySound(nil, SoundEffect.SOUND_LASERRING_WEAK, 0.8, 0.8)

		else
			entity:BloodExplode()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.holyLeechDeath, EntityType.ENTITY_LEECH)