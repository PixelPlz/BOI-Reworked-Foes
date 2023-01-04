local mod = BetterMonsters



function mod:prideUpdate(entity)
	if mod:CheckForRev() == false and ((entity.Variant == 0 and entity.SubType <= 1) or entity.Variant == 1) then
		local sprite = entity:GetSprite()


		-- Custom laser attack
		if entity.State == NpcState.STATE_ATTACK then
			entity.State = NpcState.STATE_ATTACK3

		elseif entity.State == NpcState.STATE_ATTACK3 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				if entity.SubType == 0 then
					SFXManager():Play(SoundEffect.SOUND_BOSS_LITE_HISS, 1, 0, false, 1)

				elseif entity.SubType == 1 then
					entity.I2 = 1
				end


				-- Lasers
				for i = 0, 3 do
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(4 + entity.SubType, entity.Position, (45 - entity.I2 * 45) + (i * 90), 15, Vector(0, -30), entity), entity}
					local laser = laser_ent_pair.laser
					laser.DepthOffset = entity.DepthOffset - 10
					laser.Mass = 0

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
		
		
		-- Custom light beam attack for champion Pride
		elseif entity.State == NpcState.STATE_ATTACK2 and entity.SubType == 1 then
			entity.State = NpcState.STATE_ATTACK4
		
		elseif entity.State == NpcState.STATE_ATTACK4 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Beam") then
				local room = Game():GetRoom()
				local vector = room:GetGridPosition(room:GetGridIndex(room:FindFreeTilePosition(Isaac.GetRandomPosition(), 80)))
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, vector, Vector.Zero, entity):GetSprite().Color = sunBeamColor
			
			elseif sprite:IsEventTriggered("Shoot") then
				SFXManager():Play(SoundEffect.SOUND_ANGEL_BEAM, 0.9)
			end

			if sprite:IsFinished("Attack02") then
				entity.State = NpcState.STATE_MOVE
			end
		end


		-- Better blood color
		if entity:HasMortalDamage() then
			if entity.Variant == 0 then
				if entity.SubType == 1 then
					entity.SplatColor = Color(0,0,0, 1, 0.75,0.66,0.31)
				else
					entity.SplatColor = Color(0,0,0, 1, 0.31,0.31,0.31)
				end

			elseif entity.Variant == 1 then
				entity.SplatColor = Color(0,0,0, 1, 0.75,0.31,0.46)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.prideUpdate, EntityType.ENTITY_PRIDE)



function mod:championPrideReward(entity)
	-- Crack the Sky
	if mod:CheckForRev() == false and entity.SpawnerType == EntityType.ENTITY_PRIDE and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 and entity.SubType ~= 160 then
		entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 160, false, true, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.championPrideReward, PickupVariant.PICKUP_COLLECTIBLE)



-- Ultra Pride baby
function mod:florianInit(entity)
	if entity.Variant == 2 then
		local fly = Isaac.Spawn(EntityType.ENTITY_ETERNALFLY, 0, 0, entity.Position, Vector.Zero, nil)
		fly.Parent = entity
		entity.Child = fly
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.florianInit, EntityType.ENTITY_BABY)