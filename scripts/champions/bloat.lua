local mod = BetterMonsters



function mod:bloatInit(entity)
	-- Replace green champion's eyes with Spitties
	if entity.Variant == 11 and entity.SpawnerType == EntityType.ENTITY_PEEP and entity.SpawnerEntity.SubType == 1 then
		entity:Remove()
		Isaac.Spawn(EntityType.ENTITY_SPITTY, 0, 0, entity.Position, Vector.Zero, entity)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.bloatInit, EntityType.ENTITY_PEEP)

function mod:bloatUpdate(entity)
	if entity.Variant == 1 and entity.SubType == 1 then
		local sprite = entity:GetSprite()

		-- Replace brimstone attack with chubber attack for green champion
		if entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3 then
			entity.State = entity.State + 2
			sprite:Play("AttackAlt01", true)


		elseif entity.State == NpcState.STATE_ATTACK4 or entity.State == NpcState.STATE_ATTACK5 then
			if sprite:IsEventTriggered("Shoot") then
				entity:PlaySound(SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1)
				entity:PlaySound(SoundEffect.SOUND_MEATHEADSHOOT, 0.9, 0, false, 1)
				entity:PlaySound(SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR, 1, 0, false, 1)

				-- Chubber worms
				for i = 0, 1 do
					local angle = 90
					if entity.State == NpcState.STATE_ATTACK5 then
						angle = 180 - (i * 180)
					end

					local worm = Isaac.Spawn(EntityType.ENTITY_VIS, 22, 0, entity.Position + Vector(-16 + (i * 32), 0), Vector.FromAngle(angle) * 20, entity)
					worm.Parent = entity
					worm.DepthOffset = entity.DepthOffset + 50
					worm.PositionOffset = Vector(0, -40)

					mod:shootEffect(entity, 2, Vector(-12 + (i * 24), -46), Color(0.4,0.8,0.4, 1, 0,0.4,0), 1, true)
				end
			end


			if sprite:GetFrame() == 54 then
				entity:PlaySound(SoundEffect.SOUND_MEAT_JUMPS, 1, 0, false, 1)
			end
			if sprite:IsFinished("AttackAlt01") then
				entity.State = NpcState.STATE_MOVE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.bloatUpdate, EntityType.ENTITY_PEEP)