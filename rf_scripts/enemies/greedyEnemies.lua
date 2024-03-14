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
	and entity.FrameCount > 20 and not entity:IsDead() -- Don't try to pick up coins during the appear animation / post-mortem
	and not entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then -- Friendly enemies shouldn't pick up coins

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
					break
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



-- Hanger
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.CollectCoins, EntityType.ENTITY_HANGER)
-- Greed Gaper
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.CollectCoins, EntityType.ENTITY_GREED_GAPER)
-- Fiend Folio Dangler
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.CollectCoins, 610)