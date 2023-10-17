local mod = ReworkedFoes



function mod:IsaacUpdate(entity)
	-- Wing flaps for all variants
	if entity:GetSprite():IsEventTriggered("Flap") then
		mod:PlaySound(nil, SoundEffect.SOUND_ANGEL_WING, 0.7)
	end


	-- Isaac specific
	if entity.Variant == 0 then
		-- Make him actually fly in his 3rd phase
		if entity:GetSprite():IsFinished("2Evolve") then
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		end


		-- Light beam attack variations
		-- Replace default version
		if entity.State == NpcState.STATE_ATTACK2 and (entity.I1 == 1000 or entity.I1 == 2000) then
			local chosen = mod:Random(1, 3)

			if chosen >= 2 then
				entity.State = NpcState.STATE_ATTACK3
				entity.V1 = Vector(chosen, 0)
				entity.ProjectileDelay = 0
			end


		-- Custom versions
		elseif entity.State == NpcState.STATE_ATTACK3 then
			if entity.ProjectileDelay <= 0 then
				local room = Game():GetRoom()
				local allOutsideRoom = true

				-- Expanding ring
				if entity.V1.X == 2 then
					local beamCount = math.max(1, entity.V1.Y * 4)

					for i = 0, beamCount - 1 do
						-- Get position
						local angle = 360 / beamCount * i
						local pos = room:GetCenterPos() + Vector.FromAngle(45 + angle):Resized(entity.V1.Y * 55)

						if room:IsPositionInRoom(pos, 0) then
							Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, pos, Vector.Zero, entity)
							allOutsideRoom = false
						end
					end


				-- 2 alternating lines
				else
					local leftBasePos  = room:GetTopLeftPos() 	  + Vector(20, 15)
					local rightBasePos = room:GetBottomRightPos() - Vector(20, 25)

					for dir = -1, 1, 2 do
						for i = 0, 5 do
							-- Get position
							local basePos = rightBasePos
							if dir == 1 then
								basePos = leftBasePos
							end
							local pos = basePos + dir * Vector(entity.V1.Y * 60, i * 100)

							if room:IsPositionInRoom(pos, 0) then
								Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, pos, Vector.Zero, entity)
								allOutsideRoom = false
							end
						end
					end
				end


				-- Stop if it covered the entire room already
				if allOutsideRoom == true then
					entity.State = NpcState.STATE_ATTACK2
					entity.I1 = 1

				-- Continue beamin'
				else
					entity.V1 = Vector(entity.V1.X, entity.V1.Y + 1)
					entity.ProjectileDelay = entity.V1.X == 3 and 6 or 8
				end

			else
				entity.ProjectileDelay = entity.ProjectileDelay - 1
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.IsaacUpdate, EntityType.ENTITY_ISAAC)