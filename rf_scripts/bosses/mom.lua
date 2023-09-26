local mod = ReworkedFoes

-- Example on how to add custom spawns: (variant and subtype can be left out to default it to 0)
-- table.insert( ReworkedFoes.MomSpawns.Mausoleum, {200, 21, 69} )
mod.MomSpawns = {
	Blue = {
		{EntityType.ENTITY_POOTER, 1},
		{EntityType.ENTITY_CLOTTY, 1},
		{EntityType.ENTITY_HOPPER, 1},
		{EntityType.ENTITY_VIS, 2},
		{EntityType.ENTITY_SPIDER},
		{EntityType.ENTITY_KEEPER},
		{EntityType.ENTITY_GURGLE},
		{EntityType.ENTITY_WALKINGBOIL},
		{EntityType.ENTITY_BUTTLICKER},
		{EntityType.ENTITY_BIGSPIDER},
	},

	Mausoleum = {
		{EntityType.ENTITY_MAW, 2},
		{EntityType.ENTITY_KNIGHT, 2},
		{EntityType.ENTITY_SUCKER},
		{EntityType.ENTITY_BONY},
		{EntityType.ENTITY_RAGLING, 1},
		{EntityType.ENTITY_PSY_HORF},
		{EntityType.ENTITY_CANDLER},
		{EntityType.ENTITY_WHIPPER},
		{EntityType.ENTITY_PON},
		{EntityType.ENTITY_VIS_FATTY, 1},
	},

	Gehenna = {
		{EntityType.ENTITY_KNIGHT, 4},
		{EntityType.ENTITY_SUCKER},
		{EntityType.ENTITY_BIGSPIDER},
		{EntityType.ENTITY_BONY},
		{EntityType.ENTITY_BEGOTTEN},
		{EntityType.ENTITY_WHIPPER},
		{EntityType.ENTITY_WHIPPER, 1},
		{EntityType.ENTITY_VIS_FATTY, 1},
		{EntityType.ENTITY_MAZE_ROAMER},
		{EntityType.ENTITY_GOAT},
	},
}



function mod:MomInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MomInit, EntityType.ENTITY_MOM)

-- Red champion eye shot
function mod:MomUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 2 then
		local sprite = entity:GetSprite()

		-- Replace default attack
		if entity.State == NpcState.STATE_ATTACK then
			entity.State = NpcState.STATE_ATTACK5
			sprite:Play("EyeLaser", true)
			entity.I2 = 0

		elseif entity.State == NpcState.STATE_ATTACK5 then
			if sprite:IsEventTriggered("Shoot") or sprite:GetFrame() == 55 or sprite:GetFrame() == 65 then
				local params = ProjectileParams()
				params.Scale = 1.4 - (entity.I2 * 0.1)
				entity:FireProjectiles(entity.Position + Vector(0, 20), (entity:GetPlayerTarget().Position - (entity.Position + Vector(0, 20))):Resized(10), 0 + entity.I2, params)
				mod:ShootEffect(entity, 2, Vector.Zero, Color.Default, 1, true)

				entity.I2 = entity.I2 + 1
				mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 1.4)
			end

			if sprite:IsFinished("EyeLaser") then
				entity.State = NpcState.STATE_IDLE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MomUpdate, EntityType.ENTITY_MOM)



--[[ New spawns ]]--
function mod:MomReplaceSpawns(entity)
	if entity.SpawnerType == EntityType.ENTITY_MOM and entity.SpawnerEntity
	and (entity.SpawnerEntity.SubType == 1 or entity.SpawnerEntity.SubType == 3)
	and not entity:GetData().newMomSpawn then
		entity:Remove()

		-- Get spawn group
		local spawnGroup = mod.MomSpawns.Blue

		if entity.SpawnerEntity.SubType == 3 then
			-- Gehenna champion
			if Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE_B then
				spawnGroup = mod.MomSpawns.Gehenna

			-- Mausoleum champion
			else
				spawnGroup = mod.MomSpawns.Mausoleum
			end
		end

		local selectedSpawn = mod:RandomIndex(spawnGroup)
		Isaac.Spawn(selectedSpawn[1], selectedSpawn[2] or 0, selectedSpawn[3] or 0, entity.Position, Vector.Zero, entity):GetData().newMomSpawn = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MomReplaceSpawns)