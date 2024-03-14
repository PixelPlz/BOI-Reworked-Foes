local mod = ReworkedFoes



function mod:HomunculusBegottenCordBreak(entity)
	if entity.Variant == 0 then
		local data = entity:GetData()

		-- Get all cord segments
		if not data.cordSegments then
			data.cordSegments = {}

			for i, segment in pairs(Isaac.FindByType(entity.Type, 10, -1, false, false)) do
				if segment.Parent and segment.Parent.Index == entity.Index then
					table.insert(data.cordSegments, segment)
				end
			end


		-- Detached
		elseif (entity.State == NpcState.STATE_ATTACK or entity:HasMortalDamage()) and entity.I2 == 0 then
			entity.I2 = 1

			-- Sound
			local sfxID = entity.Type == EntityType.ENTITY_BEGOTTEN and SoundEffect.SOUND_CHAIN_BREAK or SoundEffect.SOUND_MEATY_DEATHS
			mod:PlaySound(nil, sfxID)

			-- Effects
			for i, segment in pairs(data.cordSegments) do
				-- Begotten chain gibs
				if entity.Type == EntityType.ENTITY_BEGOTTEN then
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CHAIN_GIB, 0, segment.Position, mod:RandomVector(), entity):GetSprite().Color = Color(0.75,0.75,0.75, 1)

				-- Homunculus blood splashes
				else
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 1, segment.Position, Vector.Zero, entity).SpriteOffset = Vector(0, -20)
				end
			end

			data.cordSegments = nil
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.HomunculusBegottenCordBreak, EntityType.ENTITY_HOMUNCULUS)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.HomunculusBegottenCordBreak, EntityType.ENTITY_BEGOTTEN)