local mod = BetterMonsters
local game = Game()



function mod:nestInit(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		local stage = game:GetRoom():GetRoomConfigStage()

		-- Only replace nests on chaper 1 floors
		if (stage > 0 and stage < 4) or (stage > 26 and stage < 29) then
			entity:Remove()
			Isaac.Spawn(EntityType.ENTITY_MULLIGAN, IRFentities.mullicocoonVariant, 0, entity.Position, Vector.Zero, entity.SpawnerEntity)
		else
			entity:Morph(EntityType.ENTITY_HIVE, 40, 0, entity:GetChampionColorIdx())
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.nestInit, EntityType.ENTITY_NEST)



-- Mullicocoon
function mod:mullicocoonInit(entity)
	if entity.Variant == IRFentities.mullicocoonVariant then
		local offset = math.random(0, 359)
		for i = 1, 3 do
			local spider = Isaac.Spawn(EntityType.ENTITY_SPIDER, 0, 0, entity.Position + (Vector.FromAngle(offset + (i * 120)) * math.random(10, 30)), Vector.Zero, entity)
			spider:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			spider.Target = entity
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.mullicocoonInit, EntityType.ENTITY_MULLIGAN)

function mod:mullicocoonDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == IRFentities.mullicocoonVariant and damageSource.Type == EntityType.ENTITY_SPIDER then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.mullicocoonDMG, EntityType.ENTITY_MULLIGAN)

function mod:mullicocoonCollide(entity, target, bool)
	if entity.Variant == IRFentities.mullicocoonVariant and target.Type == EntityType.ENTITY_SPIDER then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.mullicocoonCollide, EntityType.ENTITY_MULLIGAN)

function mod:mullicocoonDeath(entity)
	if entity.Variant == IRFentities.mullicocoonVariant then
		SFXManager():Play(SoundEffect.SOUND_BOIL_HATCH, 0.8)
		
		for i = 1, 3 do
			local checkType = EntityType.ENTITY_FLY
			local spawnType = EntityType.ENTITY_SWARM_SPIDER
			
			if i == 2 then
				checkType = EntityType.ENTITY_ATTACKFLY
				spawnType = EntityType.ENTITY_SPIDER
			elseif i == 3 then
				checkType = EntityType.ENTITY_POOTER
				spawnType = EntityType.ENTITY_BIGSPIDER
			end
			
			for j, spawn in pairs(Isaac.FindByType(checkType, -1, -1, false, false)) do
				if spawn.SpawnerType == EntityType.ENTITY_MULLIGAN and spawn.SpawnerVariant == IRFentities.mullicocoonVariant then
					spawn:Remove()
					Isaac.Spawn(spawnType, 0, 0, entity.Position, Vector.Zero, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.mullicocoonDeath, EntityType.ENTITY_MULLIGAN)



-- Nest
function mod:nestUpdate(entity)
	if entity.Variant == 40 and entity.State == NpcState.STATE_ATTACK then
		local sprite = entity:GetSprite()

		if sprite:GetOverlayFrame() == 4 or sprite:GetOverlayFrame() == 5 then  -- Fuck you Bassya for changing their animation timing (JK your mod is great)
			-- Remove fly
			for i, fly in pairs(Isaac.FindByType(EntityType.ENTITY_ATTACKFLY, -1, -1, false, false)) do
				if fly.SpawnerType == EntityType.ENTITY_HIVE and fly.SpawnerVariant == 40 then
					fly:Remove()
				end
			end
			-- Spawn a spider
			if sprite:GetOverlayFrame() == 5 then
				EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + ((entity:GetPlayerTarget().Position - entity.Position):Normalized() * math.random(40, 80)), false, -6)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.nestUpdate, EntityType.ENTITY_HIVE)

function mod:nestDeath(entity)
	if entity.Variant == 40 then
		SFXManager():Play(SoundEffect.SOUND_BOIL_HATCH, 0.8)
		
		for i = 1, 3 do
			local checkType = EntityType.ENTITY_FLY
			local spawnType = EntityType.ENTITY_SWARM_SPIDER
			
			if i == 2 then
				checkType = EntityType.ENTITY_ATTACKFLY
				spawnType = EntityType.ENTITY_SPIDER
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
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.nestDeath, EntityType.ENTITY_HIVE)