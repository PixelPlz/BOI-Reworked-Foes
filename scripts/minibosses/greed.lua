local mod = BetterMonsters

local Settings = {
	CoinHealPercentage = 5,
	CoinCollectRange = 20,
	CoinMagnetRange = 40
}



-- Function for making greedy enemies collect coins
function mod:greedCollect(entity)
	-- Don't pick up coins in greed mode
	if not Game():IsGreedMode() then
		for _, pickup in pairs(Isaac.FindInRadius(entity.Position, Settings.CoinMagnetRange, EntityPartition.PICKUP)) do
			if not entity:IsDead() and pickup.Variant == PickupVariant.PICKUP_COIN and not pickup:ToPickup():IsShopItem() and pickup:ToPickup():CanReroll() == true and not pickup:GetData().greedRobber then
				if (entity.Position - pickup.Position):Length() <= Settings.CoinCollectRange then
					pickup:GetData().greedRobber = entity:ToNPC()

				elseif Game():GetRoom():CheckLine(entity.Position, pickup.Position, 0, 0, false, false) and pickup.SubType ~= CoinSubType.COIN_STICKYNICKEL then
					pickup.Position = mod:Lerp(pickup.Position, entity.Position, 0.2)
				end
			end
		end
	end
end

function mod:greedRobPickup(entity)
	local data = entity:GetData()
	local sprite = entity:GetSprite()


	-- Collect the coin
	if data.greedRobber then
		if not sprite:IsPlaying("Collect") then
			sprite:Play("Collect", true)
			data.greedRobbed = true
			data.greedRobber:SetColor(Color(1,1,1, 1, 0.5,0.5,0), 5, 1, true, false)
			
			-- Proper coin values
			local multiplier = 1
			if entity.SubType == CoinSubType.COIN_NICKEL or entity.SubType == CoinSubType.COIN_STICKYNICKEL then
				multiplier = 5
			elseif entity.SubType == CoinSubType.COIN_DIME or entity.SubType == CoinSubType.COIN_GOLDEN then
				multiplier = 10
			elseif entity.SubType == CoinSubType.COIN_DOUBLEPACK or entity.SubType == CoinSubType.COIN_LUCKYPENNY then
				multiplier = 2
			end

			-- Heal based on the coin value
			data.greedRobber:AddHealth((data.greedRobber.MaxHitPoints / 100) * Settings.CoinHealPercentage * multiplier)

			-- Add to Coffer coin projectiles
			if data.greedRobber.Type == EntityType.ENTITY_KEEPER and data.greedRobber.Variant == IRFentities.coffer then
				data.greedRobber.I1 = data.greedRobber.I1 + multiplier
			end
		end

		data.greedRobber = nil
	end


	-- Remove the coin
	if data.greedRobbed and sprite:IsPlaying("Collect") and sprite:GetFrame() == 4 then
		entity:PlayPickupSound()
		entity:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, mod.greedRobPickup, PickupVariant.PICKUP_COIN)



-- Greed
function mod:greedUpdate(entity)
	if mod:CheckForRev() == false and ((entity.Variant == 0 and entity.SubType <= 1) or entity.Variant == 1) then
		local sprite = entity:GetSprite()

		if entity.State == NpcState.STATE_ATTACK or entity.State == NpcState.STATE_ATTACK3 then
			if sprite:GetFrame() == 5 then
				entity:PlaySound(SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
			end

			-- Custom champion attack
			if entity.State == NpcState.STATE_ATTACK then
				if entity.SubType == 1 and (sprite:IsPlaying("Attack01Down") or sprite:IsPlaying("Attack01Hori") or sprite:IsPlaying("Attack01Up")) then
					entity.State = NpcState.STATE_ATTACK3
				end

			elseif entity.State == NpcState.STATE_ATTACK3 then
				if sprite:GetFrame() == 4 then
					
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_COIN
					params.BulletFlags = ProjectileFlags.EXPLODE
					params.Scale = 1.25
					entity:FireProjectiles(entity.Position, entity.V1:Normalized() * 8, 1, params)
				end

				if sprite:IsFinished(sprite:GetAnimation()) then
					entity.State = NpcState.STATE_MOVE
				end
			end
		end


		-- Unique death for champion Greed
		if entity.SubType == 1 and entity:HasMortalDamage() then
			SFXManager():Play(SoundEffect.SOUND_ULTRA_GREED_COIN_DESTROY)

			-- Particles
			for i = 0, 7 do
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GOLD_PARTICLE, 0, entity.Position, Vector.FromAngle(math.random(0, 359)) * math.random(1, 5), entity)
			end

			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, entity):GetSprite()
			effect:Load("gfx/293.000_ultragreedcoins.anm2", true)
			effect:Play("CrumbleNoDebris", true)
			effect.Scale = Vector(0.7, 0.7)
		end
	end

	mod:greedCollect(entity)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.greedUpdate, EntityType.ENTITY_GREED)

function mod:greedDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.SpawnerType == EntityType.ENTITY_GREED and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.greedDMG, EntityType.ENTITY_GREED)

-- Super Greed hitting a player
function mod:greedHit(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if (damageSource.Type == EntityType.ENTITY_PROJECTILE and damageSource.SpawnerType == EntityType.ENTITY_GREED and damageSource.SpawnerVariant == 1)
	or (damageSource.Type == EntityType.ENTITY_GREED and damageSource.Variant == 1) then
		local player = target:ToPlayer()

		-- Remove bombs
		local amount = math.min(player:GetNumBombs(), math.random(1, 2))
		player:AddBombs(-amount)

		if amount > 1 then
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, BombSubType.BOMB_NORMAL, player.Position, Vector.FromAngle(math.random(0, 359)) * math.random(4, 6), nil)
		end


		-- Remove keys
		local amount = math.min(player:GetNumKeys(), math.random(1, 2))
		player:AddKeys(-amount)

		if amount > 1 then
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_NORMAL, player.Position, Vector.FromAngle(math.random(0, 359)) * math.random(4, 6), nil)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.greedHit, EntityType.ENTITY_PLAYER)

function mod:championGreedReward(entity)
	-- Midas' Touch
	if mod:CheckForRev() == false and entity.SpawnerType == EntityType.ENTITY_GREED and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 and entity.SubType ~= CollectibleType.COLLECTIBLE_MIDAS_TOUCH then
		entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_MIDAS_TOUCH, false, true, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.championGreedReward, PickupVariant.PICKUP_COLLECTIBLE)



-- Coffer / Keeper
function mod:cofferReplace(entity)
	if entity.Variant == 0 and entity.SubType == 0 and entity.SpawnerType == EntityType.ENTITY_GREED then
		entity:Remove() -- Properly sets their stage HP

		if entity.SpawnerEntity.SubType == 0 then
			Isaac.Spawn(EntityType.ENTITY_KEEPER, IRFentities.coffer, 0, entity.Position, Vector.Zero, entity.SpawnerEntity):Update()

		elseif entity.SpawnerEntity.SubType == 1 then
			local coin = Isaac.Spawn(EntityType.ENTITY_ULTRA_COIN, 2, 0, entity.Position, Vector.Zero, entity.SpawnerEntity)
			coin:Update()
			coin:ToNPC().Scale = 0.9
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.cofferReplace, EntityType.ENTITY_HOPPER)

function mod:cofferUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.Variant == IRFentities.coffer then
		-- Go towards coins
		if not Game():IsGreedMode() then
			for _, pickup in pairs(Isaac.FindInRadius(entity.Position, 120, EntityPartition.PICKUP)) do
				if not entity:IsDead() and pickup.Variant == PickupVariant.PICKUP_COIN and not pickup:ToPickup():IsShopItem() and pickup:ToPickup():CanReroll() == true then
					entity.Target = pickup
				end
			end
		end

		-- Prevent them from shooting
		entity.ProjectileCooldown = 3
	end


	-- Also for keepers
	mod:greedCollect(entity)

	if sprite:IsPlaying("JumpDown") and sprite:GetFrame() == 22 then
		entity.Velocity = Vector.Zero
		entity.TargetPosition = entity.Position
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.cofferUpdate, EntityType.ENTITY_KEEPER)

function mod:cofferDeath(entity)
	if entity.Variant == IRFentities.coffer and entity.I1 > 0 then
		local target = entity:GetPlayerTarget()
		local params = ProjectileParams()
		params.Variant = ProjectileVariant.PROJECTILE_COIN
		
		if entity.I1 == 1 then
			entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * 8, 0, params)

		elseif entity.I1 == 3 then
			for i = 0, 2 do
				entity:FireProjectiles(entity.Position, Vector.FromAngle((target.Position - entity.Position):GetAngleDegrees() + (i * 120)) * 8, 0, params)
			end

		elseif entity.I1 == 4 then
			entity:FireProjectiles(entity.Position, Vector(8, 4), math.random(6, 7), params)

		elseif entity.I1 >= 8 then
			entity:FireProjectiles(entity.Position, Vector(8, 8), 8, params)

		else
			entity:FireProjectiles(entity.Position, Vector(8, entity.I1), 9, params)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.cofferDeath, EntityType.ENTITY_KEEPER)



-- Hanger
function mod:hangerUpdate(entity)
	mod:greedCollect(entity)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hangerUpdate, EntityType.ENTITY_HANGER)



-- Greed Gaper
function mod:greedGaperUpdate(entity)
	mod:greedCollect(entity)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.greedGaperUpdate, EntityType.ENTITY_GREED_GAPER)



-- Fiend Folio Dangler
function mod:danglerUpdate(entity)
	if FiendFolio then
		mod:greedCollect(entity)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.danglerUpdate, 610)