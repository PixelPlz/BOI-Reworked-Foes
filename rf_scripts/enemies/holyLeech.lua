local mod = ReworkedFoes



function mod:HolyLeechUpdate(entity)
	-- Death animation
	if entity.Variant == 2 and entity:HasMortalDamage() then
		entity:GetSprite():Play("Death", true)
		entity.State = NpcState.STATE_DEATH
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.HolyLeechUpdate, EntityType.ENTITY_LEECH)



-- Create the Crack the Sky beam
function mod:HolyLeechSkyBeam(entity)
	Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, entity:GetPlayerTarget().Position, Vector.Zero, entity)
	mod:PlaySound(nil, SoundEffect.SOUND_LASERRING_WEAK, 0.8, 0.8)
end

function mod:HolyLeechRender(entity, offset)
	if entity.Variant == 2 and entity:GetSprite():IsEventTriggered("Spawn") and entity.I2 == 0 then
		mod:HolyLeechSkyBeam(entity)
		entity.I2 = 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.HolyLeechRender, EntityType.ENTITY_LEECH)

function mod:HolyLeechDeath(entity, target, bool)
	if entity.Variant == 2 then
		-- Beam failsafe
		if entity.I2 == 0 then
			mod:HolyLeechSkyBeam(entity)
		else
			entity:BloodExplode()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.HolyLeechDeath, EntityType.ENTITY_LEECH)