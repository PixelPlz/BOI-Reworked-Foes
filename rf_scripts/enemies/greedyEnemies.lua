local mod = ReworkedFoes



--[[ Make greedy enemies collect coins ]]--
function mod:CollectCoins(entity)
	if mod.Config.CoinStealing and not Game():IsGreedMode() -- Don't pick up coins in Greed Mode
	and entity.FrameCount >= 20 and not entity:IsDead() -- Don't try to pick up coins during the appear animation / post-mortem
	and not entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then -- Don't pick up coins if friendly
		local coins = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN)

		for i, pickup in pairs(coins) do
			local radius = entity.Size + pickup.Size + 15
			local data = pickup:GetData()

			if pickup.Position:Distance(entity.Position) <= radius -- In range
			and pickup.SubType ~= CoinSubType.COIN_STICKYNICKEL -- Not a Sticky Nickel
			and not data.greedPickedUp then -- Not already picked up
				data.greedPickedUp = entity

				-- Remove the coin
				pickup.Velocity = Vector.Zero
				pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				pickup:GetSprite():Play("Collect", true)
				pickup:ToPickup():PlayPickupSound()


				-- Heal based on the coin value
				local value = 1

				-- Nickels
				if entity.SubType == CoinSubType.COIN_NICKEL or entity.SubType == CoinSubType.COIN_STICKYNICKEL then
					value = 5
				-- Dime / Golden
				elseif entity.SubType == CoinSubType.COIN_DIME or entity.SubType == CoinSubType.COIN_GOLDEN then
					value = 10
				-- Double
				elseif entity.SubType == CoinSubType.COIN_DOUBLEPACK then
					value = 2
				end

				local onePercent = entity.MaxHitPoints / 100
				entity:AddHealth(onePercent * 2 * value)
				entity:SetColor(Color(1,1,1, 1, 0.5,0.5,0), 5, 255, true)


				-- Add to Coffer coin projectiles
				if entity.Type == EntityType.ENTITY_KEEPER and entity.Variant == mod.Entities.Coffer then
					entity.I1 = entity.I1 + value
				end
			end
		end
	end
end

-- Collected coin
function mod:CollectedCoin(pickup)
	local sprite = pickup:GetSprite()

	if pickup:GetData().greedPickedUp
	and sprite:IsPlaying("Collect") and sprite:GetFrame() > 5 then
		pickup:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, mod.CollectedCoin, PickupVariant.PICKUP_COIN)





-- Coffer / Keeper
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
		-- Target coins on the ground
		if mod.Config.CoinStealing and not Game():IsGreedMode()
		and not entity:IsDead() and not entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
			local radius = 120

			for _, pickup in pairs( Isaac.FindInRadius(entity.Position, radius, EntityPartition.PICKUP) ) do
				if pickup.Variant == PickupVariant.PICKUP_COIN
				and pickup.SubType ~= CoinSubType.COIN_STICKYNICKEL -- Not a Sticky Nickel
				and not pickup:GetData().greedPickedUp then -- Not already picked up
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