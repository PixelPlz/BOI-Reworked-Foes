local mod = ReworkedFoes



function mod:FlamingFattyUpdate(entity)
	if entity.Variant == 2 then
		mod:EmberParticles(entity, Vector(0, -48))

		-- Fire ring
		if entity.State == NpcState.STATE_ATTACK and entity:GetSprite():IsEventTriggered("Shoot") then
			mod:CreateFireRing(entity, 0, 2, 10, 40, 1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.FlamingFattyUpdate, EntityType.ENTITY_FATTY)

-- Turn regular fatties into flaming ones when burnt
function mod:FattyIgnite(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if Game():GetRoom():HasWater() == false -- Not in a flooded room
	and entity.Variant == 0 and (damageFlags & DamageFlag.DAMAGE_FIRE > 0) then
		entity:ToNPC():Morph(EntityType.ENTITY_FATTY, 2, 0, entity:ToNPC():GetChampionColorIdx())
		mod:PlaySound(nil, SoundEffect.SOUND_FIREDEATH_HISS)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.FattyIgnite, EntityType.ENTITY_FATTY)