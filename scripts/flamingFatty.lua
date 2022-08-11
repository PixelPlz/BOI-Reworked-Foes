local mod = BetterMonsters
local game = Game()



function mod:flamingFattyUpdate(entity)
	if entity.Variant == 2 then
		local sprite = entity:GetSprite()

		-- Fire jet towards target
		if sprite:IsEventTriggered("Shoot") then
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_WAVE, 0, entity.Position, Vector.Zero, entity):ToEffect().Rotation = (entity:GetPlayerTarget().Position - entity.Position):GetAngleDegrees()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.flamingFattyUpdate, EntityType.ENTITY_FATTY)

function mod:flamingFattyDeath(entity)
	-- Fire ring on death
	if entity.Variant == 2 then
		local ring = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_JET, 40, entity.Position, Vector.Zero, entity)
		ring.DepthOffset = entity.DepthOffset - 10
		ring.SpriteScale = Vector(1.2, 1.2)
		SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_END)

		for i, e in pairs(Isaac.FindInRadius(entity.Position, 60, 40)) do
			local dmg = 0
			if e.Type == EntityType.ENTITY_PLAYER then
				dmg = 1
			end
			e:TakeDamage(dmg, DamageFlag.DAMAGE_FIRE, EntityRef(entity), 0)
		end
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