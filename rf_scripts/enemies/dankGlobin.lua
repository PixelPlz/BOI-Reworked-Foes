local mod = ReworkedFoes



function mod:DankGlobinUpdate(entity)
	if entity.Variant == 2 and entity.State == NpcState.STATE_IDLE then
		local sprite = entity:GetSprite()

		-- Projectiles
		if sprite:IsEventTriggered("Shoot") then
			local params = ProjectileParams()
			params.Color = mod.Colors.Tar
			entity:FireProjectiles(entity.Position, Vector(10, 0), 7, params)

			for i, spider in pairs(Isaac.FindByType(EntityType.ENTITY_SPIDER, -1, -1, false, false)) do
				if spider.SpawnerType == EntityType.ENTITY_GLOBIN and spider.SpawnerVariant == 2 then
					spider:Remove()
				end
			end


		-- Start / Stop moving
		elseif sprite:IsEventTriggered("Move") then
			entity.I1 = 1
		elseif sprite:IsEventTriggered("Regen") then
			entity.I1 = 0
		end

		-- Move towards the player
		local place = entity:GetPlayerTarget().Position
		if entity.I1 == 1 and entity.Pathfinder:HasPathToPos(place, false) then
			entity.Pathfinder:FindGridPath(place, 5.5 / 6, 500, false)

			if entity:IsFrame(4, 0) then
				mod:QuickCreep(EffectVariant.CREEP_BLACK, entity, entity.Position, 0.9)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DankGlobinUpdate, EntityType.ENTITY_GLOBIN)

function mod:DankGlobinCollision(entity, target, bool)
	if entity.Variant == 2 and entity.State == NpcState.STATE_IDLE and target.Type == EntityType.ENTITY_GLOBIN then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.DankGlobinCollision, EntityType.ENTITY_GLOBIN)