local mod = BetterMonsters
local game = Game()



function mod:chubberInit(entity)
	if entity.Variant == 22 then
		entity.Mass = 0
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		entity.MaxHitPoints = 0
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.chubberInit, EntityType.ENTITY_VIS)

function mod:chubberUpdate(entity)
	if entity.Variant == 2 then
		local sprite = entity:GetSprite()

		if sprite:IsEventTriggered("Shoot") or sprite:GetFrame() == 62 then
			entity:PlaySound(SoundEffect.SOUND_MEAT_JUMPS, 0.9, 0, false, 1)
			
			-- Blood effect
			if sprite:IsEventTriggered("Shoot") then
				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 2, entity.Position, Vector.Zero, entity):ToEffect()
				effect:GetSprite().Offset = Vector(0, -12)
				effect.SpriteScale = Vector(0.85, 0.85)
				effect.DepthOffset = entity.DepthOffset - 10
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.chubberUpdate, EntityType.ENTITY_VIS)