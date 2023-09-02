local mod = BetterMonsters



function mod:flamingFattyUpdate(entity)
	if entity.Variant == 2 then
		mod:EmberParticles(entity, Vector(0, -48))

		-- Fire ring
		if entity.State == NpcState.STATE_ATTACK then
			if entity:GetSprite():IsEventTriggered("Shoot") then
				local data = entity:GetData()
				data.startFireRing = true
				data.fireRingIndex = 0
				data.fireRingDelay = 0
			end

			mod:FireRing(entity, 80)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.flamingFattyUpdate, EntityType.ENTITY_FATTY)

-- Turn regular fatties into flaming ones when burnt
function mod:fattyIgnite(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if Game():GetRoom():HasWater() == false and target.Variant == 0 and damageFlags & DamageFlag.DAMAGE_FIRE > 0 then
		target:ToNPC():Morph(EntityType.ENTITY_FATTY, 2, 0, target:ToNPC():GetChampionColorIdx())
		mod:PlaySound(nil, SoundEffect.SOUND_FIREDEATH_HISS)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.fattyIgnite, EntityType.ENTITY_FATTY)