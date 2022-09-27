local mod = BetterMonsters
local game = Game()

local blueMomSpawns = {
	{EntityType.ENTITY_POOTER, 1},
	{EntityType.ENTITY_CLOTTY, 1},
	{EntityType.ENTITY_HOPPER, 1},
	{EntityType.ENTITY_VIS, 2},
	{EntityType.ENTITY_SPIDER, 0},
	{EntityType.ENTITY_KEEPER, 0},
	{EntityType.ENTITY_GURGLE, 0},
	{EntityType.ENTITY_WALKINGBOIL, 0},
	{EntityType.ENTITY_WALKINGBOIL, 1},
	{EntityType.ENTITY_WALKINGBOIL, 2},
	{EntityType.ENTITY_BUTTLICKER, 0},
	{EntityType.ENTITY_BIGSPIDER, 0}
}

local mausoleumMomSpawns = {
	{EntityType.ENTITY_MAW, 2},
	{EntityType.ENTITY_KNIGHT, 2},
	{EntityType.ENTITY_SUCKER, 0},
	{EntityType.ENTITY_BONY, 0},
	{EntityType.ENTITY_RAGLING, 1},
	{EntityType.ENTITY_PSY_HORF, 0},
	{EntityType.ENTITY_CANDLER, 0},
	{EntityType.ENTITY_WHIPPER, 0},
	{EntityType.ENTITY_PON, 0},
	{EntityType.ENTITY_VIS_FATTY, 1}
}

local gehennaMomSpawns = {
	{EntityType.ENTITY_KNIGHT, 4},
	{EntityType.ENTITY_SUCKER, 0},
	{EntityType.ENTITY_BIGSPIDER, 0},
	{EntityType.ENTITY_BONY, 0},
	{EntityType.ENTITY_BEGOTTEN, 0},
	{EntityType.ENTITY_WHIPPER, 0},
	{EntityType.ENTITY_WHIPPER, 1},
	{EntityType.ENTITY_VIS_FATTY, 1},
	{EntityType.ENTITY_MAZE_ROAMER, 0},
	{EntityType.ENTITY_GOAT, 0}
}



-- [[ Mom ]]--
function mod:momInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.momInit, EntityType.ENTITY_MOM)

function mod:momUpdate(entity)
	-- Extra foot for red champion
	if entity.FrameCount == 0 and entity.Variant == 10 and entity.SubType == 2 and not entity:GetData().hasFoot and game:GetRoom():GetBossID() ~= 70 then
		local foot = Isaac.Spawn(entity.Type, entity.Variant, entity.SubType, entity.Position, Vector.Zero, entity):ToNPC()
		foot:GetData().hasFoot = true
		foot.ProjectileCooldown = entity.ProjectileCooldown * 1.25
		foot.Parent = entity
		entity.Child = foot
		entity:GetData().hasFoot = true
	end


	-- Red champion
	if entity.SubType == 2 then
		local sprite = entity:GetSprite()

		-- Eye shot
		if entity.Variant == 0 then
			if entity.State == NpcState.STATE_ATTACK then
				entity.State = NpcState.STATE_ATTACK5
				sprite:Play("EyeLaser", true)
				entity.I2 = 0
			
			elseif entity.State == NpcState.STATE_ATTACK5 then
				if sprite:IsEventTriggered("Shoot") or sprite:GetFrame() == 55 or sprite:GetFrame() == 65 then
					local params = ProjectileParams()
					params.Scale = 1.4 - (entity.I2 * 0.1)
					entity:FireProjectiles(entity.Position + Vector(0, 20), (entity:GetPlayerTarget().Position - (entity.Position + Vector(0, 20))):Normalized() * 10, 0 + entity.I2, params)

					entity.I2 = entity.I2 + 1
					entity:PlaySound(SoundEffect.SOUND_BLOODSHOOT, 1.5, 0, false, 1)
				end

				if sprite:IsFinished("EyeLaser") then
					entity.State = NpcState.STATE_IDLE
				end
			end


		-- Slower feet
		elseif entity.Variant == 10 then
			if sprite:GetFrame() <= 25 then
				sprite.PlaybackSpeed = 0.85
			else
				sprite.PlaybackSpeed = 1
			end

			-- Dumb workaround for shared HP
			if entity.Parent then
				if entity.HitPoints > entity.Parent.HitPoints then
					entity.HitPoints = entity.Parent.HitPoints
				elseif entity.HitPoints < entity.Parent.HitPoints then
					entity.Parent.HitPoints = entity.HitPoints
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.momUpdate, EntityType.ENTITY_MOM)

function mod:newMomSpawns(entity)
	if entity.SpawnerType == EntityType.ENTITY_MOM and entity.SpawnerEntity and (entity.SpawnerEntity.SubType == 1 or entity.SpawnerEntity.SubType == 3) and not entity:GetData().newMomSpawn then
		entity:Remove()
		local spawn = {entity.Type, entity.Variant}

		if entity.SpawnerEntity.SubType == 1 then
			spawn = blueMomSpawns[math.random(1, #blueMomSpawns)]

		elseif entity.SpawnerEntity.SubType == 3 then
			if game:GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE_B then
				spawn = gehennaMomSpawns[math.random(1, #gehennaMomSpawns)]
			else
				spawn = mausoleumMomSpawns[math.random(1, #mausoleumMomSpawns)]
			end
		end

		Isaac.Spawn(spawn[1], spawn[2], 0, entity.Position, Vector.Zero, entity):GetData().newMomSpawn = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.newMomSpawns)