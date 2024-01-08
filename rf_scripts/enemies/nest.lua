local mod = ReworkedFoes



function mod:NestInit(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		local stage = Game():GetRoom():GetRoomConfigStage()

		-- Only replace Nests on chaper 1 floors and if they are not friendly
		if mod.Config.NoChapter1Nests == true
		and entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) == false -- Not friendly
		and ((stage > 0 and stage < 4) or (stage > 26 and stage < 29)) then -- Chapter 1
			entity:Remove()
			Isaac.Spawn(EntityType.ENTITY_MULLIGAN, mod.Entities.Mullicocoon, 0, entity.Position, Vector.Zero, entity.SpawnerEntity)
		else
			entity:Morph(EntityType.ENTITY_HIVE, 40, 0, entity:GetChampionColorIdx())
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.NestInit, EntityType.ENTITY_NEST)



--[[ Mullicocoon ]]--
function mod:MullicocoonInit(entity)
	if entity.Variant == mod.Entities.Mullicocoon then
		local offset = mod:Random(359)

		-- Spawn follower spiders
		for i = 1, 3 do
			local spider = Isaac.Spawn(EntityType.ENTITY_SPIDER, 0, 0, entity.Position + Vector.FromAngle(offset + (i * 120)):Resized(mod:Random(10, 30)), Vector.Zero, entity)
			spider:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			spider.Target = entity
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MullicocoonInit, EntityType.ENTITY_MULLIGAN)

function mod:MullicocoonDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if entity.Variant == mod.Entities.Mullicocoon and damageSource.SpawnerType == entity.Type and damageSource.SpawnerVariant == entity.Variant then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.MullicocoonDMG, EntityType.ENTITY_MULLIGAN)

function mod:MullicocoonCollision(entity, target, bool)
	if entity.Variant == mod.Entities.Mullicocoon and target.SpawnerType == entity.Type and target.SpawnerVariant == entity.Variant then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.MullicocoonCollision, EntityType.ENTITY_MULLIGAN)

function mod:MullicocoonDeath(entity)
	if entity.Variant == mod.Entities.Mullicocoon then
		mod:PlaySound(nil, SoundEffect.SOUND_BOIL_HATCH, 0.8)

		-- Replace flies with spiders
		for i = 1, 3 do
			-- Flies to Swarm Spiders
			local checkType = EntityType.ENTITY_FLY
			local spawnType = EntityType.ENTITY_SWARM_SPIDER

			-- Attack Flies to Spiders
			if i == 2 then
				checkType = EntityType.ENTITY_ATTACKFLY
				spawnType = EntityType.ENTITY_SPIDER

			-- Pooters to Big Spiders
			elseif i == 3 then
				checkType = EntityType.ENTITY_POOTER
				spawnType = EntityType.ENTITY_BIGSPIDER
			end

			for j, spawn in pairs(Isaac.FindByType(checkType, -1, -1, false, false)) do
				if spawn.SpawnerType == EntityType.ENTITY_MULLIGAN and spawn.SpawnerVariant == mod.Entities.Mullicocoon then
					spawn:Remove()
					Isaac.Spawn(spawnType, 0, 0, entity.Position, Vector.Zero, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.MullicocoonDeath, EntityType.ENTITY_MULLIGAN)



--[[ Nest ]]--
function mod:NestUpdate(entity)
	if entity.Variant == 40 and entity.State == NpcState.STATE_ATTACK then
		local sprite = entity:GetSprite()

		if sprite:GetOverlayFrame() == 4 or sprite:GetOverlayFrame() == 5 then
			-- Remove fly
			for i, fly in pairs(Isaac.FindByType(EntityType.ENTITY_ATTACKFLY, -1, -1, false, false)) do
				if fly.SpawnerType == EntityType.ENTITY_HIVE and fly.SpawnerVariant == 40 then
					fly:Remove()
				end
			end
			-- Spawn a spider
			if sprite:GetOverlayFrame() == 5 then
				local pos = entity.Position + (entity:GetPlayerTarget().Position - entity.Position):Resized(mod:Random(40, 80))
				EntityNPC.ThrowSpider(entity.Position, entity, pos, false, -6)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.NestUpdate, EntityType.ENTITY_HIVE)

function mod:NestDeath(entity)
	if entity.Variant == 40 then
		mod:PlaySound(nil, SoundEffect.SOUND_BOIL_HATCH, 0.8)

		-- Replace flies with spiders
		for i = 1, 3 do
			-- Flies to Swarm Spiders
			local checkType = EntityType.ENTITY_FLY
			local spawnType = EntityType.ENTITY_SWARM_SPIDER

			-- Attack Flies to Spiders
			if i == 2 then
				checkType = EntityType.ENTITY_ATTACKFLY
				spawnType = EntityType.ENTITY_SPIDER

			-- Pooters to Big Spiders
			elseif i == 3 then
				checkType = EntityType.ENTITY_POOTER
				spawnType = EntityType.ENTITY_BIGSPIDER
			end

			for j, spawn in pairs(Isaac.FindByType(checkType, -1, -1, false, false)) do
				if spawn.SpawnerType == EntityType.ENTITY_HIVE and spawn.SpawnerVariant == 40 then
					spawn:Remove()
					Isaac.Spawn(spawnType, 0, 0, entity.Position, Vector.Zero, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.NestDeath, EntityType.ENTITY_HIVE)