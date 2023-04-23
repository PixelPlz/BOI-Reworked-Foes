local mod = BetterMonsters



function mod:dankDeathsHeadUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()

		-- Bounce
		if entity.State == NpcState.STATE_ATTACK then
			if sprite:IsEventTriggered("Move") then
				entity.State = NpcState.STATE_MOVE
				entity.I2 = 0
			end

		-- Moving
		else
			if entity.FrameCount >= 30 then
				entity.Velocity = entity.Velocity:Normalized() * 9
			else
				entity.Velocity = entity.Velocity:Normalized() * ((entity.FrameCount - 20) * 0.9)
			end

			if entity:CollidesWithGrid() or entity.I2 == 1 then
				entity.Velocity = entity.Velocity:Normalized()
				entity.State = NpcState.STATE_ATTACK
				sprite:Play("Bounce", true)

				mod:QuickCreep(EffectVariant.CREEP_BLACK, entity, entity.Position, 1.6)
				mod:shootEffect(entity, 2, Vector(0, -15), tarBulletColor, 1, true)
				SFXManager():Play(SoundEffect.SOUND_GOOATTACH0, 0.6)
			end
		end
		
		-- Fix wrong splat color
		if entity:HasMortalDamage() then
			entity.SplatColor = Color(0,0,0, 1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.dankDeathsHeadUpdate, EntityType.ENTITY_DEATHS_HEAD)

function mod:dankDeathsHeadCollide(entity, target, bool)
	if entity.Variant == 1 and target.Type == entity.Type then
		entity:ToNPC().I2 = 1
		entity.Velocity = (entity.Position - target.Position):Normalized()

		if target.Variant == 1 and target.SubType == 0 then
			target:ToNPC().I2 = 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.dankDeathsHeadCollide, EntityType.ENTITY_DEATHS_HEAD)