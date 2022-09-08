local mod = BetterMonsters
local game = Game()

local Settings = {
	BigSpiderHP = 13,
	MaxBabyLongLegsSpawns = 3,
	BabyLongLegsSpeedNerf = 0.85
}



-- Big Spiders
function mod:bigSpiderInit(entity)
	entity.MaxHitPoints = Settings.BigSpiderHP
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.bigSpiderInit, EntityType.ENTITY_BIGSPIDER)



-- Nest
function mod:nestInit(entity)
	entity:Morph(EntityType.ENTITY_MULLIGAN, 40, 0, entity:GetChampionColorIdx())
	entity.MaxHitPoints = 13
	entity.HitPoints = 13
	
	local offset = math.random(0, 359)
	for i = 1, 3 do
		local spider = Isaac.Spawn(EntityType.ENTITY_SPIDER, 0, 0, entity.Position + (Vector.FromAngle(offset + (i * 120)) * math.random(10, 30)), Vector.Zero, entity)
		spider:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		spider.Target = entity
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.nestInit, EntityType.ENTITY_NEST)

function mod:nestUpdate(entity)
	if entity.Variant == 40 then
		entity.State = NpcState.STATE_MOVE
		entity:GetSprite():SetOverlayFrame("HeadWalk", entity:GetSprite():GetFrame())
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.nestUpdate, EntityType.ENTITY_MULLIGAN)

function mod:nestDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 40 and damageSource.Type == EntityType.ENTITY_SPIDER then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.nestDMG, EntityType.ENTITY_MULLIGAN)

function mod:nestCollide(entity, target, bool)
	if entity.Variant == 40 and target.Type == EntityType.ENTITY_SPIDER then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.nestCollide, EntityType.ENTITY_MULLIGAN)

function mod:nestDeath(entity)
	if entity.Variant == 40 then
		SFXManager():Play(SoundEffect.SOUND_BOIL_HATCH, 0.9)
		
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
				if spawn.SpawnerType == EntityType.ENTITY_MULLIGAN and spawn.SpawnerVariant == 40 then
					spawn:Remove()
					Isaac.Spawn(spawnType, 0, 0, entity.Position, Vector.Zero, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.nestDeath, EntityType.ENTITY_MULLIGAN)



-- Baby Long Legs
function mod:babyLongLegsUpdate(entity)
	local sprite = entity:GetSprite()


	entity.Velocity = entity.Velocity * Settings.BabyLongLegsSpeedNerf

	if entity.State == NpcState.STATE_ATTACK then
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


		-- Only spawn a maximum of 3 at a time
		if sprite:GetFrame() == 0 then
			if Isaac.CountEntities(entity, spawnType, spawnVariant, -1) > Settings.MaxBabyLongLegsSpawns - 1 then
				entity.State = NpcState.STATE_MOVE
			end
		end
		
		-- Swap spawns
		if entity:GetSprite():IsEventTriggered("Lay") then
			for i, stuff in pairs(Isaac.FindByType(checkType, -1, -1, false, false)) do
				if stuff.SpawnerType == EntityType.ENTITY_BABY_LONG_LEGS then
					stuff:Remove()

					Isaac.Spawn(spawnType, spawnVariant, 0, entity.Position, Vector.Zero, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SPIDER_EXPLOSION, 0, entity.Position, Vector.Zero, entity):GetSprite().Color = Color(1,1,1, 1, 1,1,1)
					
					if entity.Variant == 0 then
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_WHITE, 0, entity.Position, Vector.Zero, entity):ToEffect().Scale = 1.5
					end
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.babyLongLegsUpdate, EntityType.ENTITY_BABY_LONG_LEGS)