local mod = BetterMonsters

local Settings = {
	TouchHeal = 10,
	ItemCount = 3,
	SpeedNerf = 0.985,

	GrowAmount = 1.15,

	CreepScale = 2.25,
	CreepTime = 180,

	ItemHeal = 15,
	ItemHealBig = 30,
	
	FartScale = 1,
	FartScaleBig = 1.25,
	CloudScale = 2,

	SunBeams = 4,
	SunBeamDelay = 4,
	
	TowerBombs = 5,
	TowerBombDelay = 4,
	
	TPdistance = 280
}

local pillVoiceLines = {
	SoundEffect.SOUND_LARGER,
	SoundEffect.SOUND_PRETTY_FLY,
	SoundEffect.SOUND_SPEED_UP,
	SoundEffect.SOUND_LEMON_PARTY,
	SoundEffect.SOUND_HP_UP,
	SoundEffect.SOUND_INFESTED_EXCL,
	SoundEffect.SOUND_FRIENDS,
	SoundEffect.SOUND_BAD_GAS,
	SoundEffect.SOUND_TELEPILLS
}

local pillVoiceLinesMega = {
	SoundEffect.SOUND_MEGA_ONE_MAKES_YOU_LARGER,
	SoundEffect.SOUND_MEGA_PRETTY_FLY,
	SoundEffect.SOUND_MEGA_SPEED_UP,
	SoundEffect.SOUND_MEGA_LEMON_PARTY,
	SoundEffect.SOUND_MEGA_HEALTH_UP,
	SoundEffect.SOUND_MEGA_INFESTED,
	SoundEffect.SOUND_MEGA_FRIENDS_TIL_THE_END,
	SoundEffect.SOUND_MEGA_BAD_GAS,
	SoundEffect.SOUND_MEGA_TELEPILLS
}

local cardVoiceLines = {
	SoundEffect.SOUND_STRENGTH,
	SoundEffect.SOUND_DEATH,
	SoundEffect.SOUND_TEMPERANCE,
	SoundEffect.SOUND_HIGHT_PRIESTESS,
	SoundEffect.SOUND_THE_LOVERS,
	SoundEffect.SOUND_TOWER,
	SoundEffect.SOUND_HERMIT,
	SoundEffect.SOUND_SUN,
	SoundEffect.SOUND_FOOL
}



function mod:lustInit(entity)
	if mod:CheckForRev() == false and ((entity.Variant == 0 and entity.SubType <= 1) or entity.Variant == 1) then
		local data = entity:GetData()

		data.speedUp = false
		data.crushRocks = false
		data.hasCreep = false

		-- Champion specific
		if entity.SubType == 1 then
			data.sunBeams = false
			data.towerBombs = false
			data.foolPosition = entity.Position
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.lustInit, EntityType.ENTITY_LUST)

function mod:lustUpdate(entity)
	if mod:CheckForRev() == false and ((entity.Variant == 0 and entity.SubType <= 1) or entity.Variant == 1) then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local room = Game():GetRoom()


		-- Lasting effects --
		-- Nerf their speed a bit if they don't have a speed up
		if data.speedUp == true then
			entity:SetColor(Color(1,1,0.5, 1), 10, 10, false, true)
		else
			entity.Velocity = entity.Velocity * Settings.SpeedNerf
		end

		-- Destroy rocks
		if data.crushRocks == true then
			local grid = room:GetGridEntityFromPos(entity.Position + (entity.Velocity:Normalized() * (entity.Scale * 26)))
			if grid ~= nil and grid.CollisionClass < 4 and grid.CollisionClass > 1 then
				grid:Destroy(true)
			end
		end

		-- Make eternal flies keep up properly
		if entity.Child then
			entity.Child.Velocity = entity.Velocity
		end

		-- Leave behind creep
		if data.hasCreep == true and entity:IsFrame(3, 0) then
			mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 0.8 * entity.Scale)
		end

		-- Sun beams
		if data.sunBeams == true then
			if entity.StateFrame < Settings.SunBeams then
				if entity.ProjectileCooldown <= 0 then
					local vector = room:GetGridPosition(room:GetGridIndex(room:FindFreeTilePosition(Isaac.GetRandomPosition(), 80)))
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, vector, Vector.Zero, entity):GetSprite().Color = sunBeamColor
					entity.StateFrame = entity.StateFrame + 1
					entity.ProjectileCooldown = Settings.SunBeamDelay
				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end
			
			else
				entity.StateFrame = 0
				entity.ProjectileCooldown = 0
				data.sunBeams = false
			end
		end
		
		-- Tower bombs
		if data.towerBombs == true then
			if entity.StateFrame < Settings.TowerBombs then
				if entity.ProjectileCooldown <= 0 then
					-- The first 3 always spawn near the center of the room
					local vector = room:GetGridPosition(room:GetGridIndex(room:FindFreeTilePosition(Isaac.GetRandomPosition(), 80)))
					if entity.StateFrame < 3 then
						vector = room:GetGridPosition(room:GetGridIndex(room:FindFreeTilePosition(room:GetClampedPosition(room:GetCenterPos() + Vector.FromAngle(math.random(0, 359)) * math.random(40, 80), 80), 80)))
					end

					Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_TROLL, 0, vector, Vector.Zero, entity)
					entity.StateFrame = entity.StateFrame + 1
					entity.ProjectileCooldown = Settings.TowerBombDelay
				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end
			
			else
				entity.StateFrame = 0
				entity.ProjectileCooldown = 0
				data.towerBombs = false
			end
		end


		-- Use items
		if entity.State == NpcState.STATE_ATTACK then
			mod:LoopingAnim(sprite, "Use0" .. entity.I2)

			if sprite:GetFrame() == 4 then
				local playSFX = false

				-- One time use effects --
				-- Grow and get the ability to crush rocks
				if entity.I2 == 1 then
					playSFX = true
					entity.Scale = entity.Scale * Settings.GrowAmount
					data.crushRocks = true
					entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)


				-- Pretty flies / Bone orbitals
				elseif entity.I2 == 2 then
					if entity.SubType == 1 then
						SFXManager():Play(SoundEffect.SOUND_SUMMONSOUND)
						for i = 0, 3 do
							Isaac.Spawn(200, IRFentities.boneOrbital, 0, entity.Position, Vector.Zero, entity).Parent = entity
						end

					else
						playSFX = true
						for i = 1, 1 + entity.Variant do
							Isaac.Spawn(EntityType.ENTITY_ETERNALFLY, 0, 0, entity.Position, Vector.Zero, entity).Parent = entity
						end
					end


				-- Speed up
				elseif entity.I2 == 3 then
					if entity.SubType == 1 then
						SFXManager():Play(SoundEffect.SOUND_BLOODBANK_SPAWN)
						data.hasCreep = true
					else
						playSFX = true
						data.speedUp = true
					end


				-- Multiple use effects --
				-- Lemon party creep / High Priestess stomp
				elseif entity.I2 == 4 then
					if entity.SubType == 1 then
						SFXManager():Play(SoundEffect.SOUND_MOM_VOX_EVILLAUGH, 0.8)
						local foot = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.MOM_FOOT_STOMP, 0, entity:GetPlayerTarget().Position, Vector.Zero, entity)
						foot.Target = entity:GetPlayerTarget()
						foot:GetSprite().PlaybackSpeed = 0.95

					else
						if entity.Variant == 1 then
							for i = 1, 4 do
								mod:QuickCreep(EffectVariant.CREEP_YELLOW, entity, entity.Position + (Vector.FromAngle(i * 90) * 40), Settings.CreepScale, (Settings.CreepTime / 3) * 2)
							end
						else
							mod:QuickCreep(EffectVariant.CREEP_YELLOW, entity, entity.Position, Settings.CreepScale, Settings.CreepTime)
						end

						mod:shootEffect(entity, 4, Vector.Zero, Color(0,0,0, 1, 1,1,0), 1, true)
						SFXManager():Play(SoundEffect.SOUND_GASCAN_POUR)
					end


				-- Heal
				elseif entity.I2 == 5 then
					playSFX = true
					local amount = Settings.ItemHeal
					local sound = SoundEffect.SOUND_VAMP_GULP

					if entity.Variant == 1 or entity.SubType == 1 then
						amount = Settings.ItemHealBig
						sound = SoundEffect.SOUND_VAMP_DOUBLE
					end

					SFXManager():Play(sound)
					entity:AddHealth((entity.MaxHitPoints / 100) * amount)
					entity:SetColor(Color(1,1,1, 1, 0.65,0,0), 15, 1, true, false)

					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, entity.Position, Vector.Zero, entity)
					effect:ToEffect():FollowParent(entity)
					effect:GetSprite().Offset = Vector(0, -40)
					effect.DepthOffset = entity.DepthOffset + 1


				-- Infested spiders / Tower bombs
				elseif entity.I2 == 6 then
					if entity.SubType == 1 then
						data.towerBombs = true

					else
						local bigBool = false
						if entity.Variant == 1 then
							bigBool = true
						end

						SFXManager():Play(SoundEffect.SOUND_BOIL_HATCH, 0.8)
						for i = 0, 1 do
							EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + (Vector.FromAngle(math.random(0, 359)) * math.random(80, 120)), bigBool, -10)
						end
					end


				-- Friends till the end flies / Hermit Greed Gaper
				elseif entity.I2 == 7 then
					if entity.SubType == 1 then
						SFXManager():Play(SoundEffect.SOUND_SUMMONSOUND)
						Isaac.Spawn(EntityType.ENTITY_GREED_GAPER, 0, 0, entity.Position + Vector(0, 10), Vector.Zero, entity)
					
					else
						local type = EntityType.ENTITY_ATTACKFLY
						if entity.Variant == 1 then
							type = EntityType.ENTITY_MOTER
						end

						local offset = math.random(0, 359)
						for i = 0, 2 - entity.Variant do
							Isaac.Spawn(type, 0, 0, entity.Position + (Vector.FromAngle(offset + (i * 120)) * 10), Vector.Zero, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						end
					end


				-- Bad gas fart cloud / Sun light beams + heal
				elseif entity.I2 == 8 then
					if entity.SubType == 1 then
						SFXManager():Play(SoundEffect.SOUND_HOLY)
						data.sunBeams = true
						entity:AddHealth((entity.MaxHitPoints / 100) * Settings.ItemHeal)
						entity:SetColor(sunBeamColor, 15, 1, true, false)

					else
						local fartScale = Settings.FartScale
						if entity.Variant == 1 then
							fartScale = Settings.FartScaleBig
							Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 0, entity.Position, Vector.Zero, entity):ToEffect().Scale = (Settings.CloudScale * entity.Scale) -- Poison cloud
						end

						Game():Fart(entity.Position, 85 * entity.Scale * fartScale, entity, entity.Scale * fartScale, 0, Color.Default)
					end


				-- Teleport
				elseif entity.I2 == 9 then
					local position = entity.Position
					if entity.SubType == 1 then
						position = data.foolPosition
					else
						position = entity:GetPlayerTarget().Position + ((room:GetCenterPos() - entity:GetPlayerTarget().Position):Normalized() * Settings.TPdistance)
						position = room:FindFreePickupSpawnPosition(position, 40, true, false)
					end

					SFXManager():Play(SoundEffect.SOUND_HELL_PORTAL2)
					entity:SetColor(Color(1,1,1, 1, 1,1,1), 15, 1, true, false)

					entity.Position = position
					entity.Velocity = Vector.Zero

					-- Also teleport any orbitals
					local type = EntityType.ENTITY_ETERNALFLY
					local variant = 0
					if entity.SubType == 1 then
						type = 200
						variant = IRFentities.boneOrbital
					end

					for i, children in pairs(Isaac.FindByType(type, variant, -1, false, true)) do
						if children.Parent.Index == entity.Index then
							children.Position = entity.Position
						end
					end
				end


				-- Play announcer and pill / card sounds
				if entity.SubType == 1 then
					SFXManager():Play(cardVoiceLines[entity.I2], 1.1)
					SFXManager():Play(SoundEffect.SOUND_BOOK_PAGE_TURN_12, 1)
				
				else
					local array = pillVoiceLines
					local sound = SoundEffect.SOUND_POWERUP_SPEWER
					if entity.Variant == 1 then
						array = pillVoiceLinesMega
						sound = SoundEffect.SOUND_POWERUP_SPEWER_AMPLIFIED
					end
					SFXManager():Play(array[entity.I2], 1.1)

					if playSFX == true then
						SFXManager():Play(sound)
					end
				end
			end


			entity.Velocity = mod:StopLerp(entity.Velocity)
			if sprite:GetFrame() == 21 then
				entity.State = NpcState.STATE_MOVE
			end

			-- Disable AI when using items
			return true


		else
			-- Use item at 75%, 50% and 25% health
			if entity.HitPoints <= entity.MaxHitPoints - ((entity.MaxHitPoints / (Settings.ItemCount + 1)) * (entity.I1 + 1)) then
				entity.I1 = entity.I1 + 1
				entity.State = NpcState.STATE_ATTACK

				-- Pick one use effects first
				if entity.I2 == 0 then
					entity.I2 = math.random(1, 3)
				else
					entity.I2 = math.random(4, 9)
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.lustUpdate, EntityType.ENTITY_LUST)

function mod:lustDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if mod:CheckForRev() == false and ((target.Variant == 0 and target.SubType <= 1) or target.Variant == 1) then
		-- Only take 10% damage from things spawned by Lust
		if damageSource.SpawnerType == EntityType.ENTITY_LUST then
			if not (damageFlags & DamageFlag.DAMAGE_NOKILL > 0) then
				target:TakeDamage(damageAmount / 10, damageFlags + DamageFlag.DAMAGE_NOKILL, damageSource, damageCountdownFrames)
				return false
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.lustDMG, EntityType.ENTITY_LUST)

function mod:lustHit(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Type == EntityType.ENTITY_PLAYER and mod:CheckForRev() == false
	and (damageSource.Type == EntityType.ENTITY_LUST and damageSource.Entity and ((damageSource.Variant == 0 and damageSource.Entity.SubType <= 1) or damageSource.Variant == 1)) then
		local lust = damageSource.Entity

		lust:AddHealth((lust.MaxHitPoints / 100) * Settings.TouchHeal)
		SFXManager():Play(SoundEffect.SOUND_KISS_LIPS1, 1.1)
		lust:SetColor(Color(1,1,1, 1, 0.5,0,0), 12, 1, true, false)
		
		local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, lust.Position, Vector.Zero, lust)
		effect:ToEffect():FollowParent(lust)
		effect:GetSprite().Offset = Vector(0, -40)
		effect.DepthOffset = lust.DepthOffset + 1
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.lustHit)



function mod:championLustReward(entity)
	if mod:CheckForRev() == false and entity.SpawnerType == EntityType.ENTITY_LUST and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 then
		-- Card Reading
		if entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity.SubType ~= 660 then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 660, false, true, false)
		
		-- Cards
		elseif entity.Variant == PickupVariant.PICKUP_PILL then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, 0, false, true, false)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.championLustReward)