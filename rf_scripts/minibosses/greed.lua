local mod = ReworkedFoes



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