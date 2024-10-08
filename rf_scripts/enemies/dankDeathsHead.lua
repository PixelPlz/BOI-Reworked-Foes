local mod = ReworkedFoes



function mod:DankDeathsHeadUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()

		-- Moving
		if entity.State == NpcState.STATE_MOVE then
			if not sprite:IsPlaying("Bounce") then
				mod:LoopingAnim(sprite, "Idle")
			end

			-- Stop briefly when hitting a wall or another Dank Death's Head
			if entity:CollidesWithGrid() or entity.I2 == 1 then
				entity.State = NpcState.STATE_STOMP
				sprite:Play("Bounce", true)
				entity.TargetPosition = entity.Velocity
				entity.Velocity = Vector.Zero

				-- Creep
				local offset = mod:Random(359)
				for i = 1, 3 do
					local pos = entity.Position + Vector.FromAngle(offset + i * 120):Resized(15)
					mod:QuickCreep(EffectVariant.CREEP_BLACK, entity, pos, 1.5)
				end

				-- Effects
				mod:PlaySound(nil, SoundEffect.SOUND_GOOATTACH0, 0.5)

				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 2, entity.Position, Vector.Zero, entity):GetSprite()
				effect.Color = mod.Colors.Tar
				effect.Offset = Vector(0, -12)

			else
				mod:MoveDiagonally(entity, 10, 0.15)
			end


		-- Bounce
		elseif entity.State == NpcState.STATE_STOMP then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Move") then
				entity.State = NpcState.STATE_MOVE
				entity.Velocity = entity.TargetPosition:Normalized()
				entity.I2 = 0
			end
		end


		-- Splat color fix
		if entity:HasMortalDamage() then
			entity.SplatColor = mod.Colors.Tar
		end

		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DankDeathsHeadUpdate, EntityType.ENTITY_DEATHS_HEAD)

function mod:DankDeathsHeadCollision(entity, target, bool)
	if entity.Variant == 1 and target.Type == entity.Type and target.Variant == entity.Variant then
		entity:ToNPC().I2 = 1
		entity.Velocity = (entity.Position - target.Position):Normalized()
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.DankDeathsHeadCollision, EntityType.ENTITY_DEATHS_HEAD)