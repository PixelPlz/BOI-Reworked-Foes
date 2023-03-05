local mod = BetterMonsters

-- Available variables:
-- StateFrame - index of the orbital in its group
-- V1 - X: offset based on the amount of other orbitals the parent has / Y: current rotation
-- V2 - X: rotation speed / Y: distance from parent

-- I1 - unused
-- I2 - unused
-- ProjectileCooldown - unused
-- ProjectileDelay - unused



function mod:boneOrbitalInit(entity)
	if entity.Variant == IRFentities.boneOrbital then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_BLOOD_SPLASH | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)

		entity.V2 = Vector(4, 40) -- Rotation speed / Distance from parent

		-- Play random animation
		entity:GetSprite():Play("Idle" .. math.random(0, 7), true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.boneOrbitalInit, 200)

function mod:boneOrbitalUpdate(entity)
	if entity.Variant == IRFentities.boneOrbital then
		if entity.Parent then
			-- Get offset
			local siblingCount = 0
			local leaderRotation = Vector.Zero

			for i, sibling in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, true)) do
				if sibling:HasCommonParentWithEntity(entity) then
					sibling:ToNPC().StateFrame = i
					siblingCount = siblingCount + 1

					-- Match the oldest sibling's rotation
					if i == 1 then
						leaderRotation = sibling:ToNPC().V1
					else
						sibling:ToNPC().V1 = leaderRotation
					end
				end
			end

			-- Orbit parent
			entity.V1 = Vector(((360 / siblingCount) * entity.StateFrame), entity.V1.Y + entity.V2.X) -- Rotation offset / Current rotation
			if entity.V1.Y >= 360 then
				entity.V1 = Vector(entity.V1.X, entity.V1.Y - 360)
			end
			entity.Position = mod:Lerp(entity.Position, entity.Parent.Position + (Vector.FromAngle(entity.V1.X + entity.V1.Y) * entity.V2.Y), 0.1)
			entity.Velocity = entity.Parent.Velocity

		else
			entity:Kill()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.boneOrbitalUpdate, 200)