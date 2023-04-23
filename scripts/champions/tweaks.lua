local mod = BetterMonsters



--[[ Golden Hollow hitting a player ]]--
function mod:goldenHollowHit(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_LARRYJR and damageSource.Variant == 1 and damageSource.Entity.SubType == 3 then
		local player = target:ToPlayer()

		-- Remove coins
		local amount = math.min(player:GetNumCoins(), math.random(2, 4))
		player:AddCoins(-amount)

		if amount > 1 then
			local dropAmount = math.min(amount, math.random(1, 3))
			for i = 1, dropAmount do
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, player.Position, Vector.FromAngle(math.random(0, 359)) * math.random(4, 6), nil)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.goldenHollowHit, EntityType.ENTITY_PLAYER)



--[[ Peep ]]--
function mod:peepUpdate(entity)
	if entity.Variant == 0 then
		local sprite = entity:GetSprite()

		-- Remove Yellow champion piss attack
		if entity.SubType == 1 and entity.State == NpcState.STATE_SUMMON and sprite:GetFrame() == 0 then
			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Attack01", true)
			entity:PlaySound(SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR, 1, 0, false, 1)

		-- Remove Blue champions jump attack
		elseif entity.SubType == 2 and entity.State == NpcState.STATE_JUMP and sprite:GetFrame() == 0 then
			if math.random(0, 1) == 1 then
				entity.State = NpcState.STATE_ATTACK
				sprite:Play("Attack01", true)
			else
				entity.State = NpcState.STATE_SUMMON
				sprite:Play("Attack02", true)
			end
		end


	-- Blue champion eye attack
	elseif entity.Variant == 10 then
		if entity.SubType == 2 then
			if entity.ProjectileCooldown <= 0 then
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_TEAR
				entity:FireProjectiles(entity.Position, (entity:GetPlayerTarget().Position - entity.Position):Normalized() * 9, 0, params)
				entity.ProjectileCooldown = 45

				SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0.8)
				mod:shootEffect(entity, 5, Vector(0, -24), Color(0,0,0, 0.5, 0.6,0.8,1), 0.1, true)

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end

		-- Set the subtype to 2
		elseif entity.SpawnerEntity and entity.SpawnerEntity.SubType == 2 then
			entity.SubType = 2
			entity.ProjectileCooldown = 30
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.peepUpdate, EntityType.ENTITY_PEEP)



--[[ The Haunt ]]--
-- Lil Haunts
function mod:lilHauntInit(entity)
	if entity.Variant == 10 and entity.SpawnerType == entity.Type and entity.SpawnerEntity and entity.SpawnerEntity.SubType > 0 then
		local sprite = entity:GetSprite()
		local suffix = {"black", "pink"}

		entity.SubType = entity.SpawnerEntity.SubType

		sprite:ReplaceSpritesheet(0, "gfx/monsters/rebirth/260.010_lilhaunt_" .. suffix[entity.SubType] .. ".png")
		sprite:LoadGraphics()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.lilHauntInit, EntityType.ENTITY_THE_HAUNT)

-- Black Haunt spiders
function mod:hauntUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 1 and entity.State == NpcState.STATE_ATTACK2 then
		local sprite = entity:GetSprite()

		-- Limit the amount of spawns
		local enemyPoints = Isaac.CountEntities(nil, EntityType.ENTITY_SPIDER, -1, -1) + Isaac.CountEntities(nil, EntityType.ENTITY_BIGSPIDER, -1, -1) * 2
		if sprite:GetFrame() == 0 and enemyPoints > 4 then
			entity.State = NpcState.STATE_ATTACK
		end

		-- Replace spiders with big spiders
		if sprite:IsEventTriggered("Shoot") then
			for i, stuff in pairs(Isaac.FindByType(EntityType.ENTITY_SPIDER, -1, -1, false, false)) do
				if stuff.SpawnerType == entity.Type and stuff.SpawnerVariant == entity.Variant then
					stuff:Remove()
				end
			end

			EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + Vector(0, 120), true, -10)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hauntUpdate, EntityType.ENTITY_THE_HAUNT)



--[[ Red Dingle ]]--
-- Turn red poops into regular ones
function mod:dingleDeath(entity)
	if entity.SubType == 1 and Isaac.CountEntities(nil, entity.Type, entity.Variant, -1) <= 1 then
		mod:removeRedPoops()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.dingleDeath, EntityType.ENTITY_DINGLE)



--[[ Red Mega Fatty ]]--
-- Replace vomit attack
function mod:megaFattyUpdate(entity)
	if entity.SubType == 1 then
		local sprite = entity:GetSprite()

		if entity.State == NpcState.STATE_ATTACK and sprite:GetFrame() == 0 then
			entity.State = NpcState.STATE_ATTACK4

		elseif entity.State == NpcState.STATE_ATTACK4 then
			if sprite:IsEventTriggered("Shoot") then
				entity.StateFrame = 0
				entity.ProjectileDelay = 0
				entity:PlaySound(SoundEffect.SOUND_MEGA_PUKE, 1, 0, false, 1)
			end

			if sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("StopShooting") then
				if entity.ProjectileDelay <= 0 then
					local params = ProjectileParams()
					params.Scale = 1.5
					params.HeightModifier = -20
					params.BulletFlags = ProjectileFlags.SINE_VELOCITY
					params.CircleAngle = 0.8 + entity.StateFrame * 0.3

					entity:FireProjectiles(entity.Position, Vector(6, 4), 9, params)
					entity.StateFrame = entity.StateFrame + 1
					entity.ProjectileDelay = 3

				else
					entity.ProjectileDelay = entity.ProjectileDelay - 1
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.megaFattyUpdate, EntityType.ENTITY_MEGA_FATTY)

-- Turn red poops into regular ones
function mod:megaFattyDeath(entity)
	if entity.SubType == 1 and Isaac.CountEntities(nil, entity.Type, entity.Variant, -1) <= 1 then
		mod:removeRedPoops()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.megaFattyDeath, EntityType.ENTITY_MEGA_FATTY)



--[[ Little Horn ]]--
-- Prevent unfair damage from hot troll bombs
function mod:hotTrollBombHit(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_BOMB and damageSource.Variant == BombVariant.BOMB_HOT and damageSource.Entity:GetSprite():IsPlaying("BombReturn") then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.hotTrollBombHit, EntityType.ENTITY_PLAYER)

-- Black champion
function mod:littleHornUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 2 then
		local sprite = entity:GetSprite()

		-- Particles
		mod:smokeParticles(entity, Vector(0, -20), 10, Vector(80, 100), Color.Default, "effects/effect_088_darksmoke_black")

		-- Re-enable pit spawning attack
		if entity.State == NpcState.STATE_ATTACK and sprite:GetFrame() == 0 and math.random(0, 2) == 2 then
			entity.State = NpcState.STATE_SUMMON2
			sprite:Play("Summon", true)
		end

		-- Spawn pits after teleporting
		if sprite:IsEventTriggered("CollisionOff") then
			local pit = Isaac.Spawn(EntityType.ENTITY_PITFALL, 2, 0, entity.Position, Vector.Zero, entity):ToNPC()
			pit:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			pit:GetData().skipAppear = true
			pit.StateFrame = 300
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.littleHornUpdate, EntityType.ENTITY_LITTLE_HORN)

-- Shadow pitfalls
function mod:shadowPitFallInit(entity)
	if entity.SpawnerEntity and entity.SpawnerType == EntityType.ENTITY_LITTLE_HORN and entity.SpawnerEntity.SubType == 2 then
		entity:GetSprite():Load("gfx/291.000_pitfall_shadow.anm2", true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.shadowPitFallInit, EntityType.ENTITY_PITFALL)

function mod:shadowPitFallUpdate(entity)
	if entity:GetData().skipAppear and entity.State == 2 then
		entity:GetSprite():SetFrame(10)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.shadowPitFallUpdate, EntityType.ENTITY_PITFALL)