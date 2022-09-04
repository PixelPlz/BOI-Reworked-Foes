local mod = BetterMonsters
local game = Game()



function mod:dankGlobinUpdate(entity)
	if entity.Variant == 2 and entity.State == NpcState.STATE_IDLE then
		local sprite = entity:GetSprite()


		if sprite:IsEventTriggered("Shoot") then
			local params = ProjectileParams()
			params.Color = tarBulletColor
			entity:FireProjectiles(entity.Position, Vector(10, 0), 6, params)
			
			for i, spider in pairs(Isaac.FindByType(EntityType.ENTITY_SPIDER, -1, -1, false, false)) do
				if spider.SpawnerType == EntityType.ENTITY_GLOBIN and spider.SpawnerVariant == 2 then
					spider:Remove()
				end
			end

		elseif sprite:IsEventTriggered("Move") then
			entity.I1 = 1
		elseif sprite:IsEventTriggered("Regen") then
			entity.I1 = 0
		end


		local place = entity:GetPlayerTarget().Position
		if entity.I1 == 1 and entity.Pathfinder:HasPathToPos(place, false) then
			entity.Pathfinder:FindGridPath(place, 0.85, 500, false)

			if entity:IsFrame(3, 0) then
				local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_BLACK, 0, entity.Position, Vector.Zero, entity):ToEffect()
				creep.Scale = 0.75
				creep:Update()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.dankGlobinUpdate, EntityType.ENTITY_GLOBIN)

function mod:dankGlobinCollide(entity, target, bool)
	if entity.Variant == 2 and entity.State == NpcState.STATE_IDLE and target.Type == EntityType.ENTITY_GLOBIN then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.dankGlobinCollide, EntityType.ENTITY_GLOBIN)