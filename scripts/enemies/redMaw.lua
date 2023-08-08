local mod = BetterMonsters



function mod:redMawUpdate(entity)
	if entity.Variant == 1 then
		-- Prime
		if entity.Position:Distance(entity:GetPlayerTarget().Position) <= 120 and entity.I1 == 0 then
			entity.I1 = 1
			entity.I2 = 60
		end


		if entity.I1 == 1 then
			-- Flashing
			local frame = math.floor(entity.I2 / 10) + 1
			if entity:IsFrame(frame, 0) then
				entity:SetColor(Color(1,1,1, 1, 0.6,0,0), 2, 1, false, false)
			end

			-- Speed up
			entity.Velocity = entity.Velocity * (1.08 - entity.I2 / 1000)

			-- Explode animation
			if entity.I2 == 4 then
				entity:GetSprite():Play("Shoot", true)
				entity.State = NpcState.STATE_ATTACK
			end

			-- Explode
			if entity.I2 <= 0 then
				entity:TakeDamage(entity.MaxHitPoints * 2, 0, EntityRef(entity), 0)
			else
				entity.I2 = entity.I2 - 1
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.redMawUpdate, EntityType.ENTITY_MAW)

function mod:redMawDeath(entity)
	if entity.Variant == 1 and entity.I1 == 1 and entity.I2 <= 0 then
		entity:FireProjectiles(entity.Position, Vector(7.5, 0), 7, ProjectileParams())
		entity:FireProjectiles(entity.Position, Vector(4, 0), 7, ProjectileParams())
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.redMawDeath, EntityType.ENTITY_MAW)