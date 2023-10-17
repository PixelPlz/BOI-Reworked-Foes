local mod = ReworkedFoes



function mod:DankDeathsHeadUpdate(entity)
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
			-- Slowly speed up after spawning
			if entity.FrameCount >= 30 then
				entity.Velocity = entity.Velocity:Resized(10)
			else
				entity.Velocity = entity.Velocity:Resized((entity.FrameCount - 20) * 1)
			end

			if entity:CollidesWithGrid() or entity.I2 == 1 then
				entity.Velocity = entity.Velocity:Normalized()
				entity.State = NpcState.STATE_ATTACK
				sprite:Play("Bounce", true)

				mod:QuickCreep(EffectVariant.CREEP_BLACK, entity, entity.Position, 1.6)
				mod:ShootEffect(entity, 2, Vector(0, -15), mod.Colors.Tar, 1, true)
				mod:PlaySound(nil, SoundEffect.SOUND_GOOATTACH0, 0.5)
			end
		end

		-- Splat color
		if entity:HasMortalDamage() then
			entity.SplatColor = mod.Colors.Tar
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DankDeathsHeadUpdate, EntityType.ENTITY_DEATHS_HEAD)

function mod:DankDeathsHeadCollision(entity, target, bool)
	if entity.Variant == 1 and target.Type == entity.Type and target.Variant == entity.Variant then
		entity:ToNPC().I2 = 1
		entity.Velocity = (entity.Position - target.Position):Normalized()

		target:ToNPC().I2 = 1
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.DankDeathsHeadCollision, EntityType.ENTITY_DEATHS_HEAD)