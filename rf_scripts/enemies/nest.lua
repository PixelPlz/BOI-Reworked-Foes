local mod = ReworkedFoes



local replaceStageConfigs = { 1, 2, 3, 27, 28, }

function mod:NestInit(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		local replaced = false

		-- Replace Nests in chapter 1 with Mullicocoons
		if mod.Config.NoChapter1Nests and not entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
			local currentStageConfig = Game():GetRoom():GetRoomConfigStage()

			for i, stageConfig in pairs(replaceStageConfigs) do
				if currentStageConfig == stageConfig then
					Isaac.Spawn(EntityType.ENTITY_MULLIGAN, mod.Entities.Mullicocoon, 0, entity.Position, Vector.Zero, entity.SpawnerEntity)

					entity.Visible = false
					entity:Remove()

					replaced = true
					break
				end
			end
		end

		-- Replace them with the reworked version in other chapters
		if not replaced then
			entity:Morph(EntityType.ENTITY_HIVE, mod.Entities.Nest, 0, entity:GetChampionColorIdx())
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.NestInit, EntityType.ENTITY_NEST)

if REPENTOGON then
	function mod:NestMorph(entity, eType, eVariant, eSubType, championIdx)
		if eType == EntityType.ENTITY_NEST and eVariant == 0 and eSubType == 0 then
			return { EntityType.ENTITY_HIVE, mod.Entities.Nest, 0 }
		end
	end
	mod:AddCallback(ModCallbacks.MC_PRE_NPC_MORPH, mod.NestMorph)
end



-- Replace Mulligan flies with spiders
function mod:SpiderMulliganSpawns(entity)
	mod:PlaySound(nil, SoundEffect.SOUND_BOIL_HATCH, 0.75)

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
			if spawn.SpawnerType == entity.Type and spawn.SpawnerVariant == entity.Variant then
				spawn:Remove()
				Isaac.Spawn(spawnType, 0, 0, entity.Position, Vector.Zero, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			end
		end
	end
end



--[[ Mullicocoon ]]--
function mod:MullicocoonInit(entity)
	if entity.Variant == mod.Entities.Mullicocoon then
		local offset = mod:Random(359)

		-- Spawn the follower spiders
		for i = 1, 3 do
			local angle = offset + (i * 120)
			local distance = mod:Random(10, 30)
			local pos = entity.Position + Vector.FromAngle(angle):Resized(distance)

			local spider = Isaac.Spawn(EntityType.ENTITY_SPIDER, 0, 0, pos, Vector.Zero, entity)
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
		mod:SpiderMulliganSpawns(entity)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.MullicocoonDeath, EntityType.ENTITY_MULLIGAN)



--[[ Nest ]]--
function mod:NestUpdate(entity)
	if entity.Variant == mod.Entities.Nest and entity.State == NpcState.STATE_ATTACK then
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
	if entity.Variant == mod.Entities.Nest then
		mod:SpiderMulliganSpawns(entity)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.NestDeath, EntityType.ENTITY_HIVE)