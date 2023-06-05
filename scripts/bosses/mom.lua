local mod = BetterMonsters

IRFmomSpawns = {
	Blue = {
		{EntityType.ENTITY_POOTER, 1},
		{EntityType.ENTITY_CLOTTY, 1},
		{EntityType.ENTITY_HOPPER, 1},
		{EntityType.ENTITY_VIS, 2},
		{EntityType.ENTITY_SPIDER, 0},
		{EntityType.ENTITY_KEEPER, 0},
		{EntityType.ENTITY_GURGLE, 0},
		{EntityType.ENTITY_WALKINGBOIL, 0},
		{EntityType.ENTITY_BUTTLICKER, 0},
		{EntityType.ENTITY_BIGSPIDER, 0},
	},

	Mausoleum = {
		{EntityType.ENTITY_MAW, 2},
		{EntityType.ENTITY_KNIGHT, 2},
		{EntityType.ENTITY_SUCKER, 0},
		{EntityType.ENTITY_BONY, 0},
		{EntityType.ENTITY_RAGLING, 1},
		{EntityType.ENTITY_PSY_HORF, 0},
		{EntityType.ENTITY_CANDLER, 0},
		{EntityType.ENTITY_WHIPPER, 0},
		{EntityType.ENTITY_PON, 0},
		{EntityType.ENTITY_VIS_FATTY, 1},
	},

	Gehenna = {
		{EntityType.ENTITY_KNIGHT, 4},
		{EntityType.ENTITY_SUCKER, 0},
		{EntityType.ENTITY_BIGSPIDER, 0},
		{EntityType.ENTITY_BONY, 0},
		{EntityType.ENTITY_BEGOTTEN, 0},
		{EntityType.ENTITY_WHIPPER, 0},
		{EntityType.ENTITY_WHIPPER, 1},
		{EntityType.ENTITY_VIS_FATTY, 1},
		{EntityType.ENTITY_MAZE_ROAMER, 0},
		{EntityType.ENTITY_GOAT, 0},
	},
}



-- [[ Mom ]]--
function mod:momInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.momInit, EntityType.ENTITY_MOM)

-- Red champion eye shot
function mod:momUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 2 then
		local sprite = entity:GetSprite()

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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.momUpdate, EntityType.ENTITY_MOM)

function mod:newMomSpawns(entity)
	if entity.SpawnerType == EntityType.ENTITY_MOM and entity.SpawnerEntity and (entity.SpawnerEntity.SubType == 1 or entity.SpawnerEntity.SubType == 3) and not entity:GetData().newMomSpawn then
		entity:Remove()
		local spawn = {entity.Type, entity.Variant}

		-- Blue champion
		if entity.SpawnerEntity.SubType == 1 then
			spawn = mod:RandomIndex(IRFmomSpawns.Blue)

		elseif entity.SpawnerEntity.SubType == 3 then
			-- Gehenna champion
			if Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE_B then
				spawn = mod:RandomIndex(IRFmomSpawns.Gehenna)

			-- Mausoleum champion
			else
				spawn = mod:RandomIndex(IRFmomSpawns.Mausoleum)
			end
		end

		Isaac.Spawn(spawn[1], spawn[2], 0, entity.Position, Vector.Zero, entity):GetData().newMomSpawn = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.newMomSpawns)