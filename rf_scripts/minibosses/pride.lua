local mod = ReworkedFoes



function mod:PrideInit(entity)
	if mod:CheckValidMiniboss(entity) then
		if entity.Variant == 0 then
			-- Champion
			if mod:IsRFChampion(entity, "Pride") then
				entity.SplatColor = mod.Colors.PrideHoly
			-- Regular
			else
				entity.SplatColor = mod.Colors.PrideGray
			end

		-- Super
		elseif entity.Variant == 1 then
			entity.SplatColor = mod.Colors.PridePink
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.PrideInit, EntityType.ENTITY_PRIDE)

function mod:PrideUpdate(entity)
	if mod:CheckValidMiniboss(entity) then
		local sprite = entity:GetSprite()

		-- Replace default laser attack
		if entity.State == NpcState.STATE_ATTACK then
			entity.State = NpcState.STATE_ATTACK3

		-- Custom laser attack
		elseif entity.State == NpcState.STATE_ATTACK3 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				local laserVariant = LaserVariant.PRIDE
				if mod:IsRFChampion(entity, "Pride") then
					laserVariant = LaserVariant.LIGHT_BEAM
				end

				local baseAngle = 45
				if entity.I2 >= 1 or mod:IsRFChampion(entity, "Pride") then
					baseAngle = 0
				end

				-- Lasers
				for i = 0, 3 do
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(laserVariant, entity.Position, baseAngle + (i * 90), 15, Vector(0, -30), entity), entity}
					local laser = laser_ent_pair.laser
					laser.DepthOffset = entity.DepthOffset - 10
					laser.Mass = 0

					-- Pink laser for Super Pride
					if entity.Variant == 1 then
						laser:GetSprite():ReplaceSpritesheet(0, "gfx/effects/effect_018_lasereffects02_pink.png")
						laser:GetSprite():LoadGraphics()
					end
				end

				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_HISS)

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
		elseif entity.State == NpcState.STATE_ATTACK2 and mod:IsRFChampion(entity, "Pride") then
			entity.State = NpcState.STATE_ATTACK4

		elseif entity.State == NpcState.STATE_ATTACK4 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Create the beams
			if sprite:IsEventTriggered("Beam") then
				local vector = Game():GetRoom():FindFreePickupSpawnPosition(Isaac.GetRandomPosition(), 40, false, false)
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, vector, Vector.Zero, entity):GetSprite().Color = mod.Colors.SunBeam

			-- Blast!
			elseif sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(nil, SoundEffect.SOUND_ANGEL_BEAM, 0.9)
			end

			if sprite:IsFinished("Attack02") then
				entity.State = NpcState.STATE_MOVE
			end
		end


		-- Fix blood color
		if entity:IsDead() then
			if entity.Variant == 0 then
				-- Champion
				if mod:IsRFChampion(entity, "Pride") then
					entity.SplatColor = mod.Colors.PrideHoly
				-- Regular
				else
					entity.SplatColor = mod.Colors.PrideGray
				end

			-- Super
			elseif entity.Variant == 1 then
				entity.SplatColor = mod.Colors.PridePink
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PrideUpdate, EntityType.ENTITY_PRIDE)



function mod:ChampionPrideReward(pickup)
	-- Crack the Sky
	if mod:CheckMinibossDropReplacement(pickup, EntityType.ENTITY_PRIDE, "Pride")
	and pickup.SubType ~= CollectibleType.COLLECTIBLE_CRACK_THE_SKY then
		pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_CRACK_THE_SKY, false, true, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.ChampionPrideReward, PickupVariant.PICKUP_COLLECTIBLE)