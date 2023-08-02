local mod = BetterMonsters

local Settings = {
	TouchHeal = 10,
	SpeedNerf = 0.98,

	GrowAmount = 1.15,
	ItemHeal = 12,

	TowerBombs = 5,
	TowerBombDelay = 4,

	SunBeams = 5,
	SunBeamDelay = 4
}

local lustVoiceLines = {
	pills = {
		SoundEffect.SOUND_LARGER,
		SoundEffect.SOUND_PRETTY_FLY,
		SoundEffect.SOUND_SPEED_UP,
		SoundEffect.SOUND_LEMON_PARTY,
		SoundEffect.SOUND_HP_UP,
		SoundEffect.SOUND_INFESTED_EXCL,
		SoundEffect.SOUND_FRIENDS,
		SoundEffect.SOUND_BAD_GAS
	},

	horsePills = {
		SoundEffect.SOUND_MEGA_ONE_MAKES_YOU_LARGER,
		SoundEffect.SOUND_MEGA_PRETTY_FLY,
		SoundEffect.SOUND_MEGA_SPEED_UP,
		SoundEffect.SOUND_MEGA_LEMON_PARTY,
		SoundEffect.SOUND_MEGA_HEALTH_UP,
		SoundEffect.SOUND_MEGA_INFESTED,
		SoundEffect.SOUND_MEGA_FRIENDS_TIL_THE_END,
		SoundEffect.SOUND_MEGA_BAD_GAS
	},

	cards = {
		SoundEffect.SOUND_STRENGTH,
		SoundEffect.SOUND_DEATH,
		SoundEffect.SOUND_TEMPERANCE,
		SoundEffect.SOUND_HIGHT_PRIESTESS,
		SoundEffect.SOUND_THE_LOVERS,
		SoundEffect.SOUND_TOWER,
		SoundEffect.SOUND_HERMIT,
		SoundEffect.SOUND_SUN
	}
}



function mod:lustInit(entity)
	if mod:CheckValidMiniboss(entity) == true then
		local data = entity:GetData()

		data.speedUp = false
		data.crushRocks = false
		data.hasCreep = false

		-- Champion specific
		if entity.SubType == 1 then
			data.sunBeams = false
			data.towerBombs = false
		end

		data.attacks = {4,5,6,7,8}
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.lustInit, EntityType.ENTITY_LUST)

function mod:lustUpdate(entity)
	if mod:CheckValidMiniboss(entity) == true then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local room = Game():GetRoom()


		-- Persistent effects --
		-- Nerf her speed if she doesn't have a speed up
		if data.speedUp ~= true then
			entity.Velocity = entity.Velocity * Settings.SpeedNerf
		end


		-- Destroy rocks
		if data.crushRocks == true then
			local pos = entity.Position + entity.Velocity:Resized(entity.Scale * entity.Size) + entity.Velocity:Resized(20)
			room:DestroyGrid(room:GetGridIndex(pos), true)
		end


		-- Leave behind creep
		if data.hasCreep == true and entity:IsFrame(3, 0) then
			mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position)
		end


		-- Tower bombs
		if data.towerBombs == true then
			if entity.StateFrame < Settings.TowerBombs then
				-- Spawn delay
				if entity.ProjectileCooldown <= 0 then
					-- The first 3 always spawn near the center of the room
					local vector = room:FindFreePickupSpawnPosition(Isaac.GetRandomPosition(), 40, false, true)
					if entity.StateFrame < 3 then
						vector = room:FindFreePickupSpawnPosition(room:GetCenterPos() + mod:RandomVector(mod:Random(40, 80)), 40, false, true)
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


		-- Sun beams
		if data.sunBeams == true then
			if entity.StateFrame < Settings.SunBeams then
				-- Spawn delay
				if entity.ProjectileCooldown <= 0 then
					local vector = Game():GetRoom():FindFreePickupSpawnPosition(Isaac.GetRandomPosition(), 40, false, false)
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, vector, Vector.Zero, entity):GetSprite().Color = IRFcolors.SunBeam
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



		-- Use items --
		if entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = mod:StopLerp(entity.Velocity)
			if sprite:IsPlaying("WalkHori") or sprite:IsPlaying("WalkVert") then
				sprite:Play("Use0" .. entity.I2, true)
			end


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
						mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
						for i = 0, 3 do
							Isaac.Spawn(IRFentities.Type, IRFentities.BoneOrbital, 0, entity.Position, Vector.Zero, entity).Parent = entity
						end

					else
						playSFX = true
						for i = 1, 1 + entity.Variant do
							Isaac.Spawn(EntityType.ENTITY_ETERNALFLY, 0, 0, entity.Position, Vector.Zero, entity).Parent = entity
						end
					end


				-- Speed up / Temparance blood trail
				elseif entity.I2 == 3 then
					if entity.SubType == 1 then
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODBANK_SPAWN)
						data.hasCreep = true
					else
						playSFX = true
						data.speedUp = true
						entity:SetColor(Color(1,1,0.5, 1), -1, 0, false, false)
					end



				-- Attack effects --
				-- Lemon party creep / High Priestess stomp
				elseif entity.I2 == 4 then
					if entity.SubType == 1 then
						mod:PlaySound(nil, SoundEffect.SOUND_MOM_VOX_EVILLAUGH, 0.8)

						local foot = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.MOM_FOOT_STOMP, 0, entity.Position, Vector.Zero, entity)
						foot.Target = entity:GetPlayerTarget()
						foot:GetSprite().PlaybackSpeed = 0.95

					else
						if entity.Variant == 1 then
							for i = 0, 2 do
								local offset = mod:Random(359)
								mod:QuickCreep(EffectVariant.CREEP_YELLOW, entity, entity.Position + Vector.FromAngle(offset + i * 120):Resized(mod:Random(30, 40)), 2.5, 240)
							end
						else
							mod:QuickCreep(EffectVariant.CREEP_YELLOW, entity, entity.Position, 2.5, 240)
						end

						mod:ShootEffect(entity, 3, Vector.Zero, Color(0,0,0, 1, 1,1,0), 1, true)
						mod:PlaySound(nil, SoundEffect.SOUND_GASCAN_POUR)
					end


				-- Heal
				elseif entity.I2 == 5 then
					playSFX = true
					local amount = Settings.ItemHeal
					local sound = SoundEffect.SOUND_VAMP_GULP

					if entity.Variant == 1 or entity.SubType == 1 then
						amount = Settings.ItemHeal * 2
						sound = SoundEffect.SOUND_VAMP_DOUBLE
					end

					mod:PlaySound(entity, sound)
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
						for i = 0, 1 do
							EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + mod:RandomVector(mod:Random(80, 120)), entity.Variant == 1, -10)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_BOIL_HATCH, 0.8)
					end


				-- Friends till the end flies / Hermit Greed Gaper
				elseif entity.I2 == 7 then
					if entity.SubType == 1 then
						mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
						Isaac.Spawn(EntityType.ENTITY_GREED_GAPER, 0, 0, entity.Position + Vector(0, 10), Vector.Zero, entity)
					
					else
						local type = EntityType.ENTITY_ATTACKFLY
						if entity.Variant == 1 then
							type = EntityType.ENTITY_MOTER
						end

						local offset = mod:Random(359)
						for i = 0, 2 - entity.Variant do
							Isaac.Spawn(type, 0, 0, entity.Position + Vector.FromAngle(offset + (i * 120)):Resized(10), Vector.Zero, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						end
					end


				-- Bad gas fart cloud / Sun light beams + heal
				elseif entity.I2 == 8 then
					if entity.SubType == 1 then
						mod:PlaySound(nil, SoundEffect.SOUND_HOLY)
						data.sunBeams = true
						entity:AddHealth((entity.MaxHitPoints / 100) * Settings.ItemHeal)
						entity:SetColor(IRFcolors.SunBeam, 15, 1, true, false)

					else
						Game():Fart(entity.Position, entity.Scale * 100, entity, entity.Scale, 0, Color.Default)

						-- Super Lust poison cloud
						if entity.Variant == 1 then
							Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 0, entity.Position, Vector.Zero, entity):ToEffect().Scale = 2
						end
					end
				end



				-- Play announcer and pill / card sounds --
				-- Champion Lust
				if entity.SubType == 1 then
					mod:PlaySound(nil, lustVoiceLines.cards[entity.I2], 1.1)
					mod:PlaySound(nil, SoundEffect.SOUND_BOOK_PAGE_TURN_12)

				else
					local array = lustVoiceLines.pills
					local sound = SoundEffect.SOUND_POWERUP_SPEWER

					-- Super Lust
					if entity.Variant == 1 then
						array = lustVoiceLines.horsePills
						sound = SoundEffect.SOUND_POWERUP_SPEWER_AMPLIFIED
					end

					mod:PlaySound(nil, array[entity.I2], 1.1)
					if playSFX == true then
						mod:PlaySound(nil, sound)
					end
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end

			-- Disable AI when using items
			return true



		-- Use item at 75%, 50% and 25% health
		elseif entity.FrameCount > 21 and entity.HitPoints <= entity.MaxHitPoints - (entity.MaxHitPoints / 4) * (entity.I1 + 1) then
			entity.I1 = entity.I1 + 1
			entity.State = NpcState.STATE_ATTACK

			-- Pick upgrade effects first
			if entity.I1 == 1 then
				entity.I2 = mod:Random(1, 3)
			else
				local chosen = mod:Random(1, #data.attacks)
				entity.I2 = data.attacks[chosen]
				table.remove(data.attacks, chosen)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.lustUpdate, EntityType.ENTITY_LUST)

function mod:lustDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	-- Only take 10% damage from things spawned by Lust
	if mod:CheckValidMiniboss(target) == true and damageSource.SpawnerType == EntityType.ENTITY_LUST and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
		target:TakeDamage(damageAmount / 10, damageFlags + DamageFlag.DAMAGE_CLONES, damageSource, damageCountdownFrames)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.lustDMG, EntityType.ENTITY_LUST)

-- Kiss the player to heal
function mod:lustHit(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Type == EntityType.ENTITY_PLAYER
	and ((damageSource.Type == EntityType.ENTITY_LUST and mod:CheckValidMiniboss(damageSource.Entity) == true)
	or (FiendFolio and damageSource.Type == 160 and damageSource.Variant == 1343)) then -- Stinky FF compat to make Seducers heal too
		local lust = damageSource.Entity

		lust:AddHealth((lust.MaxHitPoints / 100) * Settings.TouchHeal)
		mod:PlaySound(lust, SoundEffect.SOUND_KISS_LIPS1, 1.1)
		lust:SetColor(Color(1,1,1, 1, 0.5,0,0), 12, 1, true, false)

		-- Effect
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
		if entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity.SubType ~= CollectibleType.COLLECTIBLE_CARD_READING then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_CARD_READING, false, true, false)

		-- Cards
		elseif entity.Variant == PickupVariant.PICKUP_PILL then
			entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, 0, false, true, false)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.championLustReward)