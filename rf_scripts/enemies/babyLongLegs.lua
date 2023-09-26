local mod = ReworkedFoes



function mod:BabyLongLegsUpdate(entity)
	local sprite = entity:GetSprite()

	-- Slow the fuck down
	entity.Velocity = entity.Velocity * 0.85


	-- Swap spawns
	if entity.State == NpcState.STATE_ATTACK then
		-- Get types to check for / spawn
		local checkType = EntityType.ENTITY_SPIDER
		local checkVariant = 0
		local spawnType = EntityType.ENTITY_BOIL
		local spawnVariant = 2

		if entity.Variant == 1 then
			checkType = EntityType.ENTITY_BOIL
			checkVariant = 2
			spawnType = EntityType.ENTITY_SPIDER
			spawnVariant = 0
		end

		-- Only have a maximum of 3 at a time
		if sprite:GetFrame() == 0 then
			if Isaac.CountEntities(entity, spawnType, spawnVariant, -1) > 2 then
				entity.State = NpcState.STATE_MOVE
			end
		end


		-- Replace default spawn
		if entity:GetSprite():IsEventTriggered("Lay") then
			for i, stuff in pairs(Isaac.FindByType(checkType, checkVariant, -1, false, false)) do
				if stuff.SpawnerType == EntityType.ENTITY_BABY_LONG_LEGS and stuff.SpawnerVariant == entity.Variant then
					stuff:Remove()
				end
			end

			Isaac.Spawn(spawnType, spawnVariant, 0, entity.Position, Vector.Zero, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SPIDER_EXPLOSION, 0, entity.Position, Vector.Zero, entity):GetSprite().Color = mod.Colors.WhiteShot

			if entity.Variant == 0 then
				mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position, 1.5)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BabyLongLegsUpdate, EntityType.ENTITY_BABY_LONG_LEGS)