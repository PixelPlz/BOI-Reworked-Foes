local mod = ReworkedFoes



--[[ Greed ]]--
function mod:GreedUpdate(entity)
	if mod:CheckValidMiniboss() then
		local sprite = entity:GetSprite()

		if entity.State == NpcState.STATE_ATTACK then
			-- Replace default attack for champion
			if mod:IsRFChampion(entity, "Greed")
			and (sprite:IsPlaying("Attack01Down") or sprite:IsPlaying("Attack01Hori") or sprite:IsPlaying("Attack01Up")) then
				entity.State = NpcState.STATE_ATTACK3

			-- Make them not silent while shooting
			elseif sprite:GetFrame() == 5 then
				mod:PlaySound(entity, SoundEffect.SOUND_BLOODSHOOT)
			end


		-- Custom champion attack
		elseif entity.State == NpcState.STATE_ATTACK3 then
			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_COIN
				params.BulletFlags = ProjectileFlags.EXPLODE
				params.Scale = 1.25
				params.FallingSpeedModifier = 1
				params.FallingAccelModifier = -0.1

				entity:FireProjectiles(entity.Position, entity.V1:Resized(8), 1, params)
				mod:PlaySound(entity, SoundEffect.SOUND_ULTRA_GREED_SPIT, 0.75)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end
		end



		-- Extra champion effects
		if mod:IsRFChampion(entity, "Greed") then
			-- Bling effects
			if entity:IsFrame(20, 0) then
				local bling = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ULTRA_GREED_BLING, 0, entity.Position, Vector.Zero, entity):ToEffect()
				bling:FollowParent(entity)
				bling.DepthOffset = entity.DepthOffset + 1

				-- Set offset
				local blingGuide = sprite:GetNullFrame("BlingGuide")
				local blingPos = blingGuide:GetPos() * Vector(-mod:GetSign(sprite.FlipX), 1)
				local blingScale = blingGuide:GetScale() * 10
				local blingOffset = Vector(math.random(-blingScale.X, blingScale.X), math.random(-blingScale.Y, blingScale.Y))
				bling:GetSprite().Offset = blingPos + blingOffset / 2

				bling:Update()
			end


			-- Death effects
			if entity:IsDead() then
				mod:PlaySound(nil, SoundEffect.SOUND_ULTRA_GREED_COIN_DESTROY)
				entity.SplatColor = Color(1,1,1, 0)

				-- Particles
				for i = 1, 10 do
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GOLD_PARTICLE, 0, entity.Position, mod:RandomVector(mod:Random(4, 8)), entity)
				end

				-- Flash
				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, entity):GetSprite()
				effect:Load("gfx/293.000_ultragreedcoins.anm2", true)
				effect:Play("CrumbleNoDebris", true)
				effect.Scale = Vector.One * 0.75

				-- Crater
				local crater = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_CRATER, 0, entity.Position, Vector.Zero, entity)
				crater:GetSprite().Color = mod:ColorEx({1,1,1, 0.95},   {10,7.5,0, 1})
				crater:Update()
			end
		end
	end

	mod:CollectCoins(entity)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GreedUpdate, EntityType.ENTITY_GREED)

function mod:GreedCollision(entity, target, bool)
	if target.SpawnerType == EntityType.ENTITY_GREED then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.GreedCollision, EntityType.ENTITY_GREED)

function mod:GreedDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.SpawnerType == EntityType.ENTITY_GREED and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.GreedDMG, EntityType.ENTITY_GREED)


-- Replace Greed's Hoppers
function mod:GreedHopperReplace(entity)
	if entity.Variant == 0 and entity.SubType == 0 and entity.SpawnerType == EntityType.ENTITY_GREED then
		entity:Remove() -- Properly sets their stage HP this way

		-- Champion Greed coins
		if mod:IsRFChampion(entity.SpawnerEntity, "Greed") then
			mod:PlaySound(nil, SoundEffect.SOUND_ULTRA_GREED_PULL_SLOT, 0.8)

			local coin = Isaac.Spawn(EntityType.ENTITY_ULTRA_COIN, 2, 0, entity.Position, Vector.Zero, entity.SpawnerEntity):ToNPC()
			mod:ChangeMaxHealth(coin, coin.MaxHitPoints / 2)
			coin.Scale = 0.75
			coin.SizeMulti = Vector.One * 0.75
			coin:Update()

		-- Regular Greed Coffers
		else
			Isaac.Spawn(EntityType.ENTITY_KEEPER, mod.Entities.Coffer, 0, entity.Position, Vector.Zero, entity.SpawnerEntity)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.GreedHopperReplace, EntityType.ENTITY_HOPPER)



-- Steal more pickups when Super Greed hits a player
function mod:GreedHit(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if (damageSource.Type == EntityType.ENTITY_PROJECTILE and damageSource.SpawnerType == EntityType.ENTITY_GREED and damageSource.SpawnerVariant == 1)
	or (damageSource.Type == EntityType.ENTITY_GREED and damageSource.Variant == 1) then
		local player = entity:ToPlayer()

		-- Steal bombs
		local bombAmount = math.min(player:GetNumCoins(), mod:Random(1, 2))
		player:AddBombs(-bombAmount)

		if bombAmount > 1 then
			local velocity = mod:RandomVector(mod:Random(4, 6))
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, BombSubType.BOMB_NORMAL, player.Position, velocity, player)
		end

		-- Steal keys
		local keyAmount = math.min(player:GetNumCoins(), mod:Random(1, 2))
		player:AddKeys(-keyAmount)

		if keyAmount > 1 then
			local velocity = mod:RandomVector(mod:Random(4, 6))
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_NORMAL, player.Position, velocity, player)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.GreedHit, EntityType.ENTITY_PLAYER)



function mod:ChampionGreedReward(pickup)
	-- Midas' Touch
	if mod:CheckMinibossDropReplacement(pickup, EntityType.ENTITY_GREED, "Greed")
	and pickup.SubType ~= CollectibleType.COLLECTIBLE_MIDAS_TOUCH then
		pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_MIDAS_TOUCH, false, true, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.ChampionGreedReward, PickupVariant.PICKUP_COLLECTIBLE)