local mod = BetterMonsters
local game = Game()

local cofferVariant = Isaac.GetEntityVariantByName("Coffer")

local Settings = {
	CoinHealPercentage = 5,
	CoinCollectRange = 20,
	CoinMagnetRange = 50
}



-- Function for letting greed enemies collect pickups
local function greedCollect(entity)
	if not game:IsGreedMode() then -- Don't pick up coins in greed mode
		for _, pickup in pairs(Isaac.FindInRadius(entity.Position, Settings.CoinMagnetRange, EntityPartition.PICKUP)) do
			if not entity:IsDead() and pickup.Variant == PickupVariant.PICKUP_COIN and not pickup:ToPickup():IsShopItem() and pickup:ToPickup():CanReroll() == true and not pickup:GetData().greedRobber then
				if (entity.Position - pickup.Position):Length() <= Settings.CoinCollectRange then
					pickup:GetData().greedRobber = entity
				elseif game:GetRoom():CheckLine(entity.Position, pickup.Position, 0, 0, false, false) and pickup.SubType ~= CoinSubType.COIN_STICKYNICKEL then
					pickup.Position = (pickup.Position + (entity.Position - pickup.Position) * 0.25)
				end
			end
		end
	end
end

function mod:greedRobPickup(entity)
	local data = entity:GetData()
	local sprite = entity:GetSprite()

	if data.greedRobber then
		if not sprite:IsPlaying("Collect") then
			sprite:Play("Collect", true)
			data.greedRobbed = true
			data.greedRobber:SetColor(Color(1,1,1, 1, 0.5,0.5,0), 5, 1, true, false)
			
			local multiplier = 1
			if entity.SubType == CoinSubType.COIN_NICKEL or entity.SubType == CoinSubType.COIN_STICKYNICKEL then
				multiplier = 5
			elseif entity.SubType == CoinSubType.COIN_DIME or entity.SubType == CoinSubType.COIN_GOLDEN then
				multiplier = 10
			elseif entity.SubType == CoinSubType.COIN_DOUBLEPACK or entity.SubType == CoinSubType.COIN_LUCKYPENNY then
				multiplier = 2
			end
			data.greedRobber:AddHealth((data.greedRobber.MaxHitPoints / 100) * Settings.CoinHealPercentage * multiplier)
		end
		data.greedRobber = nil
	end

	if data.greedRobbed then
		if sprite:IsPlaying("Collect") and sprite:GetFrame() == 4 then
			entity:PlayPickupSound()
			entity:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, mod.greedRobPickup)



-- Greed
function mod:greedUpdate(entity)
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
				entity:FireProjectiles(entity.Position, entity.V1, 1, params)
			end

			if sprite:IsFinished(sprite:GetAnimation()) then
				entity.State = NpcState.STATE_MOVE
			end
		end
	end

	greedCollect(entity)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.greedUpdate, EntityType.ENTITY_GREED)

function mod:greedDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.SpawnerType == EntityType.ENTITY_GREED and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.greedDMG, EntityType.ENTITY_GREED)

-- Super Greed
function mod:greedHit(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Type == EntityType.ENTITY_PLAYER and ((damageSource.SpawnerType == EntityType.ENTITY_GREED and damageSource.SpawnerVariant == 1)
	or (damageSource.Type == EntityType.ENTITY_GREED and damageSource.Variant == 1)) then
		local player = target:ToPlayer()

		-- Remove bombs
		if player:GetNumBombs() > 0 then
			player:AddBombs(-1)

			if player:GetNumBombs() > 1 then
				player:AddBombs(-1)
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, BombSubType.BOMB_NORMAL, player.Position, Vector.FromAngle(math.random(0, 359)) * math.random(4, 6), nil)
			end
		end

		-- Remove keys
		if player:GetNumKeys() > 0 then
			player:AddKeys(-1)

			if player:GetNumKeys() > 1 then
				player:AddKeys(-1)
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_NORMAL, player.Position, Vector.FromAngle(math.random(0, 359)) * math.random(4, 6), nil)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.greedHit)



function mod:championGreedReward(entity)
	-- Midas' Touch
	if entity.SpawnerType == EntityType.ENTITY_GREED and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 and entity.SubType ~= 202 then
		entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 202, false, true, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.championGreedReward, PickupVariant.PICKUP_COLLECTIBLE)



-- Coffer / Keeper
function mod:cofferReplace(entity)
	if entity.Variant == 0 and entity.SubType == 0 and entity.SpawnerType == EntityType.ENTITY_GREED then
		entity:Remove() -- Properly sets their stage HP

		if entity.SpawnerEntity.SubType == 0 then
			Isaac.Spawn(EntityType.ENTITY_KEEPER, cofferVariant, 0, entity.Position, Vector.Zero, entity.SpawnerEntity):Update()

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

	if entity.Variant == cofferVariant then
		-- Go towards coins
		if not game:IsGreedMode() then
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
	greedCollect(entity)
	if sprite:IsPlaying("JumpDown") and sprite:GetFrame() == 22 then
		entity.Velocity = Vector.Zero
		entity.TargetPosition = entity.Position
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.cofferUpdate, EntityType.ENTITY_KEEPER)



-- Hanger
function mod:hangerUpdate(entity)
	greedCollect(entity)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hangerUpdate, EntityType.ENTITY_HANGER)