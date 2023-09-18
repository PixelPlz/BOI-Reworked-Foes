local mod = BetterMonsters



function mod:prideUpdate(entity)
	if mod:CheckValidMiniboss(entity) == true then
		local sprite = entity:GetSprite()

		-- Replace default laser attack
		if entity.State == NpcState.STATE_ATTACK then
			entity.State = NpcState.STATE_ATTACK3

		-- Custom laser attack
		elseif entity.State == NpcState.STATE_ATTACK3 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_HISS)
				if entity.SubType == 1 then
					entity.I2 = 1
				end

				-- Lasers
				for i = 0, 3 do
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(4 + entity.SubType, entity.Position, (45 - entity.I2 * 45) + (i * 90), 15, Vector(0, -30), entity), entity}
					local laser = laser_ent_pair.laser
					laser.DepthOffset = entity.DepthOffset - 10
					laser.Mass = 0

					-- Pink laser for Super Pride
					if entity.Variant == 1 then
						laser:GetSprite():ReplaceSpritesheet(0, "gfx/effects/effect_018_lasereffects02_pink.png")
						laser:GetSprite():LoadGraphics()
					end
				end

			-- Super pride attacks twice
			elseif sprite:IsEventTriggered("Reset") and entity.I2 == 0 then
				entity.I2 = entity.I2 + 1
				sprite:SetFrame(14)
			end

			if sprite:IsFinished("Attack01") then
				entity.State = NpcState.STATE_MOVE
				entity.I2 = 0
			end


		-- Custom light beam attack for champion
		elseif entity.State == NpcState.STATE_ATTACK2 and entity.SubType == 1 then
			entity.State = NpcState.STATE_ATTACK4

		elseif entity.State == NpcState.STATE_ATTACK4 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Beam") then
				local vector = Game():GetRoom():FindFreePickupSpawnPosition(Isaac.GetRandomPosition(), 40, false, false)
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, vector, Vector.Zero, entity):GetSprite().Color = IRFcolors.SunBeam

			elseif sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(nil, SoundEffect.SOUND_ANGEL_BEAM, 0.9)
			end

			if sprite:IsFinished("Attack02") then
				entity.State = NpcState.STATE_MOVE
			end
		end


		-- Better blood color
		if entity:HasMortalDamage() then
			if entity.Variant == 0 then
				-- Champion
				if entity.SubType == 1 then
					entity.SplatColor = IRFcolors.PrideHoly
				-- Regular
				else
					entity.SplatColor = IRFcolors.PrideGray
				end

			-- Super
			elseif entity.Variant == 1 then
				entity.SplatColor = IRFcolors.PridePink
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.prideUpdate, EntityType.ENTITY_PRIDE)



function mod:championPrideReward(entity)
	-- Crack the Sky
	if mod:CheckForRev() == false and entity.SpawnerType == EntityType.ENTITY_PRIDE and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 and entity.SubType ~= CollectibleType.COLLECTIBLE_CRACK_THE_SKY then
		entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_CRACK_THE_SKY, false, true, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.championPrideReward, PickupVariant.PICKUP_COLLECTIBLE)