local mod = ReworkedFoes

local Settings = {
	CoinHealPercentage = 3,
	CoinCollectRange = 20,
	CoinMagnetRange = 40,
	CoinMagnetSpeed = 15
}



--[[ Make greedy enemies collect coins ]]--
function mod:CollectCoins(entity)
	if mod.Config.CoinStealing == true
	and not Game():IsGreedMode() -- Don't pick up coins in Greed Mode
	and entity.FrameCount > 20 and not entity:IsDead() then -- Don't try to pick up coins during the appear animation / post-mortem

		for _, pickup in pairs(Isaac.FindInRadius(entity.Position, Settings.CoinMagnetRange, EntityPartition.PICKUP)) do
			if pickup.Variant == PickupVariant.PICKUP_COIN and pickup.SubType ~= CoinSubType.COIN_STICKYNICKEL -- Don't try to pick up sticky nickels
			and pickup:ToPickup():CanReroll() == true -- Don't try to pick up coins that haven't finished spawning
			and not pickup:GetData().greedRobber then

				-- In collecting range
				if (entity.Position - pickup.Position):Length() <= Settings.CoinCollectRange then
					pickup:GetData().greedRobber = entity
					pickup.Velocity = Vector.Zero

				-- Not behind obstacles
				elseif Game():GetRoom():CheckLine(entity.Position, pickup.Position, 0, 0, false, false) then
					pickup.Velocity = mod:Lerp(pickup.Velocity, (entity.Position - pickup.Position):Resized(Settings.CoinMagnetSpeed), 0.25)
				end

			end
		end
	end
end

function mod:CollectedCoin(entity)
	local data = entity:GetData()
	local sprite = entity:GetSprite()


	-- Collect the coin
	if data.greedRobber then
		if not sprite:IsPlaying("Collect") then
			sprite:Play("Collect", true)
			data.greedCollected = true
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
			if data.greedRobber.Type == EntityType.ENTITY_KEEPER and data.greedRobber.Variant == mod.Entities.Coffer then
				data.greedRobber.I1 = data.greedRobber.I1 + multiplier
			end
		end

		data.greedRobber = nil
	end

	-- Remove the coin
	if data.greedCollected and sprite:IsPlaying("Collect") and sprite:GetFrame() >= 4 then
		entity:PlayPickupSound()
		entity:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, mod.CollectedCoin, PickupVariant.PICKUP_COIN)



--[[ Greed ]]--
function mod:GreedUpdate(entity)
	if mod:CheckValidMiniboss(entity) == true then
		local sprite = entity:GetSprite()

		if entity.State == NpcState.STATE_ATTACK then
			-- Replace default attack for champion
			if entity.SubType == 1 and (sprite:IsPlaying("Attack01Down") or sprite:IsPlaying("Attack01Hori") or sprite:IsPlaying("Attack01Up")) then
				entity.State = NpcState.STATE_ATTACK3

			-- Make them not silent while shooting
			elseif sprite:GetFrame() == 5 then
				mod:PlaySound(entity, SoundEffect.SOUND_BLOODSHOOT)
			end


		-- Custom champion attack
		elseif entity.State == NpcState.STATE_ATTACK3 then
			if sprite:GetFrame() == 5 then
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_COIN
				params.BulletFlags = ProjectileFlags.EXPLODE
				params.Scale = 1.25
				entity:FireProjectiles(entity.Position, entity.V1:Resized(8), 1, params)
				mod:PlaySound(entity, SoundEffect.SOUND_ULTRA_GREED_SPIT, 0.75)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end
		end


		-- Unique death for champion Greed
		if entity.SubType == 1 and entity:HasMortalDamage() then
			mod:PlaySound(nil, SoundEffect.SOUND_ULTRA_GREED_COIN_DESTROY)

			-- Particles
			for i = 0, 7 do
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GOLD_PARTICLE, 0, entity.Position, mod:RandomVector(mod:Random(1, 5)), entity)
			end

			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, entity):GetSprite()
			effect:Load("gfx/293.000_ultragreedcoins.anm2", true)
			effect:Play("CrumbleNoDebris", true)
			effect.Scale = Vector(0.7, 0.7)
		end
	end

	mod:CollectCoins(entity)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GreedUpdate, EntityType.ENTITY_GREED)

function mod:GreedDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.SpawnerType == EntityType.ENTITY_GREED and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.GreedDMG, EntityType.ENTITY_GREED)



-- Super Greed hitting a player
function mod:GreedHit(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if (damageSource.Type == EntityType.ENTITY_PROJECTILE and damageSource.SpawnerType == EntityType.ENTITY_GREED and damageSource.SpawnerVariant == 1)
	or (damageSource.Type == EntityType.ENTITY_GREED and damageSource.Variant == 1) then
		local player = entity:ToPlayer()

		-- Remove bombs
		local amount = math.min(player:GetNumBombs(), mod:Random(1, 2))
		player:AddBombs(-amount)

		if amount > 1 then
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, BombSubType.BOMB_NORMAL, player.Position, mod:RandomVector(mod:Random(4, 6)), nil)
		end


		-- Remove keys
		local amount = math.min(player:GetNumKeys(), mod:Random(1, 2))
		player:AddKeys(-amount)

		if amount > 1 then
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_NORMAL, player.Position, mod:RandomVector(mod:Random(4, 6)), nil)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.GreedHit, EntityType.ENTITY_PLAYER)



function mod:ChampionGreedReward(entity)
	-- Midas' Touch
	if mod:CheckForRev() == false and entity.SpawnerType == EntityType.ENTITY_GREED and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 and entity.SubType ~= CollectibleType.COLLECTIBLE_MIDAS_TOUCH then
		entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_MIDAS_TOUCH, false, true, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.ChampionGreedReward, PickupVariant.PICKUP_COLLECTIBLE)



--[[ Replace Greed's Hoppers ]]--
function mod:GreedHopperReplace(entity)
	if entity.Variant == 0 and entity.SubType == 0 and entity.SpawnerType == EntityType.ENTITY_GREED then
		entity:Remove() -- Properly sets their stage HP this way

		-- Champion Greed coins
		if entity.SpawnerEntity.SubType == 1 then
			local coin = Isaac.Spawn(EntityType.ENTITY_ULTRA_COIN, 2, 0, entity.Position, Vector.Zero, entity.SpawnerEntity)
			coin:ToNPC().Scale = 0.85
			coin:Update()
			mod:PlaySound(nil, SoundEffect.SOUND_ULTRA_GREED_PULL_SLOT, 0.8)

		-- Regular Greed Coffers
		else
			Isaac.Spawn(EntityType.ENTITY_KEEPER, mod.Entities.Coffer, 0, entity.Position, Vector.Zero, entity.SpawnerEntity):Update()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.GreedHopperReplace, EntityType.ENTITY_HOPPER)



--[[ Coffer / Keeper ]]--
function mod:KeeperUpdate(entity)
	local sprite = entity:GetSprite()

	-- For both
	mod:CollectCoins(entity)

	if sprite:IsPlaying("JumpDown") and sprite:GetFrame() == 22 then
		entity.Velocity = Vector.Zero
		entity.TargetPosition = entity.Position
	end


	-- For Coffers
	if entity.Variant == mod.Entities.Coffer then
		-- Follow the turning coin
		if not Game():IsGreedMode() and not entity:IsDead() then
			for _, pickup in pairs(Isaac.FindInRadius(entity.Position, Settings.CoinMagnetRange * 3, EntityPartition.PICKUP)) do
				if pickup.Variant == PickupVariant.PICKUP_COIN and pickup.SubType ~= CoinSubType.COIN_STICKYNICKEL -- Don't try to pick up sticky nickels
				and pickup:ToPickup():CanReroll() == true -- Don't try to pick up coins that haven't finished spawning
				and not pickup:GetData().greedRobber then
					entity.Target = pickup
				end
			end
		end

		-- Prevent them from shooting
		entity.ProjectileCooldown = 3
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.KeeperUpdate, EntityType.ENTITY_KEEPER)

function mod:CofferDeath(entity)
	if entity.Variant == mod.Entities.Coffer and entity.I1 > 0 then
		-- Projectiles
		local coinsToShoot = math.floor(entity.I1 / 2)

		local params = ProjectileParams()
		params.Variant = ProjectileVariant.PROJECTILE_COIN

		-- Single shot aimed at the player
		if coinsToShoot == 1 then
			entity:FireProjectiles(entity.Position, (entity:GetPlayerTarget().Position - entity.Position):Resized(8), 0, params)

		-- 4 shots in a X / + pattern
		elseif coinsToShoot == 4 then
			entity:FireProjectiles(entity.Position, Vector(8, 4), mod:Random(6, 7), params)

		-- Ring of 8 shots
		elseif coinsToShoot >= 8 then
			entity:FireProjectiles(entity.Position, Vector(8, 8), 8, params)

		else
			entity:FireProjectiles(entity.Position, Vector(8, coinsToShoot), 9, params)
		end


		-- Pickups
		local coinsToDrop = math.ceil(entity.I1 / 2)

		for i = 1, coinsToDrop do
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, entity.Position, mod:RandomVector(mod:Random(4, 6)), entity)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.CofferDeath, EntityType.ENTITY_KEEPER)



--[[ Other greedy enemies ]]--
-- Hanger
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.CollectCoins, EntityType.ENTITY_HANGER)
-- Greed Gaper
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.CollectCoins, EntityType.ENTITY_GREED_GAPER)
-- Fiend Folio Dangler
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.CollectCoins, 610)