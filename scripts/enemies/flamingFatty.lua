local mod = BetterMonsters



function mod:flamingFattyUpdate(entity)
	-- Fire ring
	if entity.Variant == 2 and entity:GetSprite():IsEventTriggered("Shoot") then
		mod:FireRing(entity)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.flamingFattyUpdate, EntityType.ENTITY_FATTY)

function mod:flamingFattyDeath(entity)
	-- Fire ring
	if entity.Variant == 2 then
		mod:FireRing(entity)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.flamingFattyDeath, EntityType.ENTITY_FATTY)

-- Turn regular fatties into flaming ones when burnt
function mod:fattyIgnite(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 0 and damageFlags & DamageFlag.DAMAGE_FIRE > 0 then
		target:ToNPC():Morph(EntityType.ENTITY_FATTY, 2, 0, target:ToNPC():GetChampionColorIdx())
		SFXManager():Play(SoundEffect.SOUND_FIREDEATH_HISS)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.fattyIgnite, EntityType.ENTITY_FATTY)