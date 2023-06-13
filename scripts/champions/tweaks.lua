local mod = BetterMonsters



--[[ Blue Larry Jr. ]]--
function mod:blueLarryJrUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 2 and not entity.Parent and entity:IsFrame(3, 0) then
		mod:QuickCreep(EffectVariant.CREEP_SLIPPERY_BROWN, entity, entity.Position, 1, 120):GetSprite().Color = IRFcolors.TearTrail
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.blueLarryJrUpdate, EntityType.ENTITY_LARRYJR)



--[[ Golden Hollow hitting a player ]]--
function mod:goldenHollowHit(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_LARRYJR and damageSource.Variant == 1 and damageSource.Entity.SubType == 3 then
		local player = target:ToPlayer()

		-- Remove coins
		local amount = math.min(player:GetNumCoins(), mod:Random(2, 4))
		player:AddCoins(-amount)

		if amount > 1 then
			local dropAmount = mod:Random(amount - 2)
			for i = 0, dropAmount do
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, player.Position, mod:RandomVector(mod:Random(4, 6)), nil)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.goldenHollowHit, EntityType.ENTITY_PLAYER)



--[[ Gray Monstro ]]--
function mod:grayMonstroUpdate(entity)
	if entity.SubType == 2 then
		local sprite = entity:GetSprite()

		-- Replace default spit attack
		if entity.State == NpcState.STATE_ATTACK and sprite:GetFrame() == 0 then
			entity.State = NpcState.STATE_ATTACK2

		-- Custom spit attack
		elseif entity.State == NpcState.STATE_ATTACK2 then
			-- Effects
			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF)

				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 5, entity.Position, Vector.Zero, entity):ToEffect()
				effect:FollowParent(entity)
				effect.DepthOffset = entity.DepthOffset + 10

				local effectSprite = effect:GetSprite()
				effectSprite.Offset = Vector(0, -25)
				effectSprite.Color = Color(1,1,1, 0.75)
				effectSprite.Scale = Vector(0.75, 0.75)
			end

			-- Projectiles
			if sprite:WasEventTriggered("Shoot") and sprite:GetFrame() < 55 then
				entity:FireBossProjectiles(1, entity:GetPlayerTarget().Position, 3, ProjectileParams())
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.grayMonstroUpdate, EntityType.ENTITY_MONSTRO)



--[[ Green Gurdy ]]--
function mod:gurdyUpdate(entity)
	if entity.SubType == 1 and entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() == 0 then
		-- Limit the amount of spawns
		local enemyPoints = Isaac.CountEntities(nil, EntityType.ENTITY_ATTACKFLY, -1, -1)
		+ Isaac.CountEntities(nil, EntityType.ENTITY_POOTER, 1, -1) * 1.5
		+ Isaac.CountEntities(nil, EntityType.ENTITY_CHARGER, -1, -1) * 1.5

		if enemyPoints >= 6.5 then
			entity.State = NpcState.STATE_IDLE
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gurdyUpdate, EntityType.ENTITY_GURDY)

function mod:greenGurdySpawns(entity)
	if entity.SpawnerType == EntityType.ENTITY_GURDY and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1
	and ((entity.Type == EntityType.ENTITY_POOTER and entity.Variant == 0) or entity.Type == EntityType.ENTITY_BOIL) then
		local spawn = {entity.Type, entity.Variant}

		-- Pooter to Super Pooter
		if entity.Type == EntityType.ENTITY_POOTER then
			spawn = {EntityType.ENTITY_POOTER, 1}

		-- Boil to Charger
		elseif entity.Type == EntityType.ENTITY_BOIL then
			spawn = {EntityType.ENTITY_CHARGER, 0}
		end

		entity:Remove()
		Isaac.Spawn(spawn[1], spawn[2], 0, entity.Position, Vector.Zero, entity.SpawnerEntity)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.greenGurdySpawns)



--[[ Black Frail ]]--
function mod:blackFrailUpdate(entity)
	if entity.Variant == 2 and entity.SubType == 1 and not entity.Parent then
		local sprite = entity:GetSprite()

		-- Replace default attacks
		if entity.State == NpcState.STATE_ATTACK2 and sprite:GetFrame() == 1 then
			entity.State = NpcState.STATE_ATTACK5
			sprite:Play("Attack2", true)

		elseif (entity.State == NpcState.STATE_ATTACK or entity.State == NpcState.STATE_ATTACK3) and sprite:GetFrame() == 1 then
			entity.State = NpcState.STATE_ATTACK4
			sprite:Play("Attack3Start", true)
			entity.ProjectileCooldown = 0


		-- Custom head attack
		elseif entity.State == NpcState.STATE_ATTACK4 then
			local data = entity:GetData()

			entity.Velocity = Vector.Zero

			-- Appear
			if entity.ProjectileCooldown == 0 then
				if sprite:GetFrame() == 4 then
					mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_BURST_OUT, 0.9)
				end

				if sprite:IsFinished() then
					entity.ProjectileCooldown = 1
					sprite:Play("Attack3Charge", true)
					mod:PlaySound(entity, SoundEffect.SOUND_FRAIL_CHARGE)
				end


			-- Charge
			elseif entity.ProjectileCooldown == 1 then
				if sprite:IsFinished() then
					entity.ProjectileCooldown = 2
					data.attacking = true
					data.attackTimer = 50
					data.attacksDone = 0
					mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_START)
					mod:PlaySound(entity, SoundEffect.SOUND_FIRE_RUSH, 0.9)
				end


			-- Shooting
			elseif entity.ProjectileCooldown == 2 then
				local target = entity:GetPlayerTarget()
				local vector = (target.Position - entity.Position)

				local suffix = mod:GetDirectionStringEX(vector:GetAngleDegrees())
				mod:LoopingAnim(sprite, "Attack3Shoot" .. suffix)

				-- Shooting
				if data.attacking == true then
					if data.attackTimer <= 0 then
						data.attacking = false
						data.attackTimer = 10
					else
						data.attackTimer = data.attackTimer - 1
					end

					if entity:IsFrame(3, 0) then
						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_FIRE
						params.Color = IRFcolors.BlueFire
						params.BulletFlags = ProjectileFlags.FIRE
						params.HeightModifier = -40
						params.FallingSpeedModifier = 5
						entity:FireProjectiles(entity.Position + vector:Resized(10), vector:Rotated(mod:Random(-10, 10)):Resized(7), 0, params)
					end

				-- Stopped
				else
					if data.attackTimer <= 0 then
						-- End
						if data.attacksDone == 2 then
							entity.ProjectileCooldown = 3
							sprite:Play("Attack3End", true)
							data.attacking = nil
							data.attackTimer = nil
							data.attacksDone = nil

						-- Continue
						else
							data.attacking = true
							data.attackTimer = 50
							data.attacksDone = data.attacksDone + 1
							mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_START)
							mod:PlaySound(entity, SoundEffect.SOUND_FIRE_RUSH)
						end

					else
						data.attackTimer = data.attackTimer - 1
					end
				end


			-- End
			else
				if sprite:GetFrame() == 4 then
					mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_ENTER_GROUND)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
					mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_ENTER_GROUND)
				end
			end
		
		
		-- Custom tail attack
		elseif entity.State == NpcState.STATE_ATTACK5 then
			entity.Velocity = Vector.Zero

			-- Sound
			if sprite:GetFrame() == 4 then
				mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_BURST_OUT, 0.9)

			-- Shoot
			elseif sprite:GetFrame() == 45 then
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_BONE
				params.Color = IRFcolors.BlackBony
				params.HeightModifier = -30
				params.FallingAccelModifier = 1.25
				params.FallingSpeedModifier = -15
				params.BulletFlags = (ProjectileFlags.BLUE_FIRE_SPAWN)

				local offset = mod:Random(359)
				for i = 0, 3 do
					entity:FireProjectiles(entity.Position, Vector.FromAngle(offset + 90 * i):Resized(6), 0, params)
				end

				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_2)

			-- Sound
			elseif sprite:GetFrame() == 85 then
				mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_ENTER_GROUND)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.blackFrailUpdate, EntityType.ENTITY_PIN)

function mod:frailDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 2 and damageSource.SpawnerType == EntityType.ENTITY_PIN then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.frailDMG, EntityType.ENTITY_PIN)

-- Turn fire waves into blue ones
function mod:frailBlueFireJet(effect)
	if effect.SpawnerType == EntityType.ENTITY_PIN and effect.SpawnerVariant == 2 and effect.SubType ~= 3 then
		effect.SubType = 3
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.frailBlueFireJet, EffectVariant.FIRE_WAVE)



--[[ Black Death ]]--
-- Horse
function mod:blackDeathUpdate(entity)
	if entity.Variant == 20 then
		-- Get the parent's subtype
		if entity.SubType == 0 and entity.SpawnerEntity and entity.SpawnerEntity.SubType > 0 then
			entity.SubType = entity.SpawnerEntity.SubType

		-- Appear horizontally to the target
		elseif entity.SubType == 1 then
			local room = Game():GetRoom()

			if entity.Position.X >= room:GetBottomRightPos().X + 200 or entity.Position.X <= room:GetTopLeftPos().X - 200 then
				entity.Position = Vector(entity.Position.X, entity:GetPlayerTarget().Position.Y)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.blackDeathUpdate, EntityType.ENTITY_DEATH)

-- Replace Red Maws with homing Scythes
function mod:replaceRedMaws(entity)
	if entity.Variant == 1 and entity.SpawnerType == EntityType.ENTITY_DEATH and entity.SpawnerEntity then
		entity:Remove()

		local scythe = Isaac.Spawn(EntityType.ENTITY_DEATH, 10, 0, entity.Position, Vector.Zero, entity.SpawnerEntity)
		scythe.Parent = entity.SpawnerEntity
		scythe:GetSprite():ReplaceSpritesheet(0, "gfx/monsters/better/death_scythe_black.png")
		scythe:GetSprite():LoadGraphics()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.replaceRedMaws, EntityType.ENTITY_MAW)



--[[ Peep ]]--
function mod:peepUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.Variant == 0 then
		-- Remove Yellow champion piss attack
		if entity.SubType == 1 and entity.State == NpcState.STATE_SUMMON and sprite:GetFrame() == 0 then
			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Attack01", true)
			mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR)

		-- Remove Blue champions jump attack
		elseif entity.SubType == 2 and entity.State == NpcState.STATE_JUMP and sprite:GetFrame() == 0 then
			if mod:Random(1) == 1 then
				entity.State = NpcState.STATE_ATTACK
				sprite:Play("Attack01", true)
			else
				entity.State = NpcState.STATE_SUMMON
				sprite:Play("Attack02", true)
			end
		end


	-- Blue champion eye
	elseif entity.Variant == 10 then
		if entity.SubType == 2 then
			mod:LoopingOverlay(sprite, "Blood", true)

			-- Idle
			if entity.State == NpcState.STATE_MOVE then
				mod:LoopingAnim(sprite, "Idle")

				if entity.ProjectileCooldown <= 0 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Shoot", true)
					entity.ProjectileCooldown = 30
				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end

			-- Attacking
			elseif entity.State == NpcState.STATE_ATTACK then
				if sprite:IsEventTriggered("Shoot") then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_TEAR
					entity:FireProjectiles(entity.Position, (entity:GetPlayerTarget().Position - entity.Position):Resized(10), 0, params)

					mod:PlaySound(nil, SoundEffect.SOUND_TEARS_FIRE, 0.8)
					mod:ShootEffect(entity, 5, Vector(0, -24), IRFcolors.TearEffect, 0.8, true)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
				end
			end

		-- Set the subtype to 2 and load  the new animations
		elseif entity.SpawnerEntity and entity.SpawnerEntity.SubType == 2 then
			entity.SubType = 2
			entity.ProjectileCooldown = 30
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.peepUpdate, EntityType.ENTITY_PEEP)



--[[ Green Bloat ]]--
function mod:bloatInit(entity)
	-- Replace the eyes with Spitties
	if entity.Variant == 11 and entity.SpawnerType == EntityType.ENTITY_PEEP and entity.SpawnerEntity.SubType == 1 then
		entity:Remove()
		Isaac.Spawn(EntityType.ENTITY_SPITTY, 0, 0, entity.Position, Vector.Zero, entity)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.bloatInit, EntityType.ENTITY_PEEP)

function mod:bloatUpdate(entity)
	if entity.Variant == 1 and entity.SubType == 1 then
		local sprite = entity:GetSprite()

		-- Replace brimstone attack with chubber attack
		if entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3 then
			entity.State = entity.State + 2
			sprite:Play("AttackAlt01", true)


		-- Chubber attack
		elseif entity.State == NpcState.STATE_ATTACK4 or entity.State == NpcState.STATE_ATTACK5 then
			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR)
				mod:PlaySound(nil, SoundEffect.SOUND_MEATHEADSHOOT)

				-- Chubber worms
				for i = -1, 1, 2 do
					local angle = 90
					if entity.State == NpcState.STATE_ATTACK5 then
						angle = i * 180
					end

					local worm = Isaac.Spawn(EntityType.ENTITY_VIS, 22, 0, entity.Position + Vector(i * 16, 0), Vector.FromAngle(angle):Resized(20), entity)
					worm.Parent = entity
					worm.DepthOffset = entity.DepthOffset + 50
					worm.PositionOffset = Vector(0, -40)

					mod:ShootEffect(entity, 2, Vector(i * 12, -46), IRFcolors.GreenBlood, 1, true)
				end
			end

			if sprite:GetFrame() == 54 then
				mod:PlaySound(SoundEffect.SOUND_MEAT_JUMPS)
			end
			if sprite:IsFinished("AttackAlt01") then
				entity.State = NpcState.STATE_MOVE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.bloatUpdate, EntityType.ENTITY_PEEP)



--[[ Gemini ]]--
function mod:geminiUpdate(entity)
	if entity.Variant == 0 and entity:IsFrame(3, 0) then
		-- Green champion
		if entity.SubType == 1 and entity.State == NpcState.STATE_ATTACK then
			mod:QuickCreep(EffectVariant.CREEP_GREEN, entity, entity.Position, 1, 120)

		-- Blue champion
		elseif entity.SubType == 2 then
			mod:QuickCreep(EffectVariant.CREEP_SLIPPERY_BROWN, entity, entity.Position, 1, 150):GetSprite().Color = IRFcolors.TearTrail
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.geminiUpdate, EntityType.ENTITY_GEMINI)



--[[ The Haunt ]]--
-- Lil Haunts
function mod:lilHauntInit(entity)
	if entity.Variant == 10 and entity.SpawnerType == entity.Type and entity.SpawnerEntity and entity.SpawnerEntity.SubType > 0 then
		local sprite = entity:GetSprite()
		local suffix = {"black", "pink"}

		entity.SubType = entity.SpawnerEntity.SubType

		sprite:ReplaceSpritesheet(0, "gfx/monsters/rebirth/260.010_lilhaunt_" .. suffix[entity.SubType] .. ".png")
		sprite:LoadGraphics()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.lilHauntInit, EntityType.ENTITY_THE_HAUNT)

-- Black Haunt spiders
function mod:hauntUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 1 and entity.State == NpcState.STATE_ATTACK2 then
		local sprite = entity:GetSprite()

		-- Limit the amount of spawns
		local enemyPoints = Isaac.CountEntities(nil, EntityType.ENTITY_SPIDER, -1, -1) + Isaac.CountEntities(nil, EntityType.ENTITY_BIGSPIDER, -1, -1) * 2
		if sprite:GetFrame() == 0 and enemyPoints > 4 then
			entity.State = NpcState.STATE_ATTACK
		end

		-- Replace spiders with big spiders
		if sprite:IsEventTriggered("Shoot") then
			for i, stuff in pairs(Isaac.FindByType(EntityType.ENTITY_SPIDER, -1, -1, false, false)) do
				if stuff.SpawnerType == entity.Type and stuff.SpawnerVariant == entity.Variant then
					stuff:Remove()
				end
			end

			EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + Vector(0, 120), true, -10)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hauntUpdate, EntityType.ENTITY_THE_HAUNT)



--[[ Red Dingle ]]--
-- Turn red poops into regular ones
function mod:dingleDeath(entity)
	if entity.SubType == 1 and Isaac.CountEntities(nil, entity.Type, entity.Variant, -1) <= 1 then
		mod:RemoveRedPoops()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.dingleDeath, EntityType.ENTITY_DINGLE)



--[[ Mega Maw ]]--
function mod:championMegaMawUpdate(entity)
	local sprite = entity:GetSprite()

	-- Red champion
	if entity.SubType == 1 then
		-- Cooldown between attacks
		if sprite:IsFinished("FireRing") then
			entity.ProjectileCooldown = 30
		end

		if entity.ProjectileCooldown > 0 then
			entity.State = NpcState.STATE_IDLE
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end

		-- Make him not silent
		if sprite:IsEventTriggered("Shoot") then
			mod:PlaySound(entity, SoundEffect.SOUND_FIRE_RUSH)
		end


	-- Black champion
	elseif entity.SubType == 2 then
		-- Replace default spit attack
		if entity.State == NpcState.STATE_ATTACK and sprite:GetFrame() == 0 then
			entity.State = NpcState.STATE_ATTACK3

		-- Custom spit attack
		elseif entity.State == NpcState.STATE_ATTACK3 then
			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.BulletFlags = (ProjectileFlags.SMART | ProjectileFlags.BURST8)
				params.Scale = 2
				mod:FireProjectiles(entity, entity.Position, (entity:GetPlayerTarget().Position - entity.Position):Resized(12), 0, params, IRFcolors.RagManPurple)
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_5)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.championMegaMawUpdate, EntityType.ENTITY_MEGA_MAW)



--[[ Red Mega Fatty ]]--
-- Replace vomit attack
function mod:redMegaFattyUpdate(entity)
	if entity.SubType == 1 then
		local sprite = entity:GetSprite()

		if entity.State == NpcState.STATE_ATTACK and sprite:GetFrame() == 0 then
			entity.State = NpcState.STATE_ATTACK4

		elseif entity.State == NpcState.STATE_ATTACK4 then
			if sprite:IsEventTriggered("Shoot") then
				entity.StateFrame = 0
				entity.ProjectileDelay = 0
				mod:PlaySound(entity, SoundEffect.SOUND_MEGA_PUKE)
			end

			if sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("StopShooting") then
				if entity.ProjectileDelay <= 0 then
					local params = ProjectileParams()
					params.Scale = 1.5
					params.HeightModifier = -20
					params.BulletFlags = ProjectileFlags.SINE_VELOCITY
					params.CircleAngle = 0.8 + entity.StateFrame * 0.3

					entity:FireProjectiles(entity.Position, Vector(6, 4), 9, params)
					entity.StateFrame = entity.StateFrame + 1
					entity.ProjectileDelay = 3

				else
					entity.ProjectileDelay = entity.ProjectileDelay - 1
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.redMegaFattyUpdate, EntityType.ENTITY_MEGA_FATTY)

-- Turn red poops into regular ones
function mod:megaFattyDeath(entity)
	if entity.SubType == 1 and Isaac.CountEntities(nil, entity.Type, entity.Variant, -1) <= 1 then
		mod:RemoveRedPoops()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.megaFattyDeath, EntityType.ENTITY_MEGA_FATTY)



--[[ The Cage ]]--
function mod:cageChampionUpdate(entity)
	local sprite = entity:GetSprite()

	-- Green champion
	if entity.SubType == 1 then
		-- Create projectiles when hitting walls
		if entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = entity.Velocity * 0.85

			if entity.ProjectileDelay <= 0 then
				if entity:CollidesWithGrid() then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_PUKE
					params.Scale = 1.25
					entity:FireProjectiles(entity.Position, Vector(8, 8), 9, params)
					entity.ProjectileDelay = 10
				end

			else
				entity.ProjectileDelay = entity.ProjectileDelay - 1
			end


		-- Projectile line when landing instead of shockwaves
		elseif entity.State == NpcState.STATE_STOMP then
			if sprite:IsEventTriggered("Landed") then
				-- Remove rock waves
				for i, rockWave in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.CRACKWAVE, 0, false, false)) do
					if rockWave.SpawnerEntity and rockWave.SpawnerEntity.Index == entity.Index then
						rockWave:Remove()
					end
				end

				entity.I1 = 0
				entity.I2 = 1
				entity.V1 = Vector(mod:Random(359), 0)
			end

			if entity.I2 == 1 and entity:IsFrame(2, 0) then
				for i = 0, 3 do
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_PUKE
					params.Scale = 1.6 - (entity.I1 * 0.1)
					params.FallingAccelModifier = 1.25
					params.FallingSpeedModifier = -16 + (entity.I1 * 2)

					local position = entity.Position + Vector.FromAngle(entity.V1.X + i * 90) * ((entity.I1 + 3) * 20)

					-- Don't spawn the creep and projectiles outside of the room
					if Game():GetRoom():IsPositionInRoom(position, 0) then
						entity:FireProjectiles(position, mod:RandomVector(), 0, params)
						mod:QuickCreep(EffectVariant.CREEP_GREEN, entity, position, 1.6 - (entity.I1 * 0.1), 60)
					end
				end

				-- Stop after 8 shots
				if entity.I1 >= 7 then
					entity.I2 = 0
				else
					entity.I1 = entity.I1 + 1
				end
			end
		end


	-- Prevent pink champion from spawning Vises
	elseif entity.SubType == 2 and entity.State == NpcState.STATE_SUMMON and sprite:GetFrame() == 0 then
		entity.State = NpcState.STATE_ATTACK2
		sprite:Play("Puking", true)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.cageChampionUpdate, EntityType.ENTITY_CAGE)

-- Green champion creep
function mod:cageCreepUpdate(effect)
	if effect.SpawnerType == EntityType.ENTITY_CAGE and effect.SpawnerEntity and effect.SpawnerEntity.SubType == 1 then
		effect:GetSprite():Load("gfx/1000.022_creep (red).anm2", true)
		effect:GetSprite().Color = IRFcolors.CageGreenCreep
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.cageCreepUpdate, EffectVariant.CREEP_GREEN)



--[[ Replace Dank Squirts from black Brownie with black Dingle ]]--
function mod:brownieDeath(entity)
	if entity.SubType == 1 and entity.State == NpcState.STATE_SPECIAL and entity:GetSprite():IsFinished() then
		local dingle = Isaac.Spawn(EntityType.ENTITY_DINGLE, 0, 2, entity.Position, Vector.Zero, entity):ToNPC()
		dingle:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		dingle.MaxHitPoints = 75
		dingle.HitPoints = dingle.MaxHitPoints
		dingle:Update()
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.brownieDeath, EntityType.ENTITY_BROWNIE)

function mod:replaceDankSquirts(entity)
	if entity.Variant == 1 and entity.SpawnerType == EntityType.ENTITY_BROWNIE then
		entity:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.replaceDankSquirts, EntityType.ENTITY_SQUIRT)



--[[ Little Horn ]]--
-- Prevent unfair damage from hot troll bombs
function mod:hotTrollBombHit(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_BOMB and damageSource.Variant == BombVariant.BOMB_HOT and damageSource.Entity:GetSprite():IsPlaying("BombReturn") then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.hotTrollBombHit, EntityType.ENTITY_PLAYER)

-- Black champion
function mod:littleHornUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 2 then
		local sprite = entity:GetSprite()

		-- Particles
		mod:SmokeParticles(entity, Vector(0, -20), 10, Vector(80, 100), Color.Default, "effects/effect_088_darksmoke_black")

		-- Re-enable pit spawning attack
		if entity.State == NpcState.STATE_ATTACK and sprite:GetFrame() == 0 and mod:Random(2) == 2 then
			entity.State = NpcState.STATE_SUMMON2
			sprite:Play("Summon", true)
		end

		-- Spawn pits after teleporting
		if sprite:IsEventTriggered("CollisionOff") then
			local pit = Isaac.Spawn(EntityType.ENTITY_PITFALL, 2, 0, entity.Position, Vector.Zero, entity):ToNPC()
			pit:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			pit:GetData().skipAppear = true
			pit.StateFrame = 270
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.littleHornUpdate, EntityType.ENTITY_LITTLE_HORN)

-- Shadow pitfalls
function mod:shadowPitFallInit(entity)
	if entity.SpawnerEntity and entity.SpawnerType == EntityType.ENTITY_LITTLE_HORN and entity.SpawnerEntity.SubType == 2 then
		entity:GetSprite():Load("gfx/291.000_pitfall_shadow.anm2", true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.shadowPitFallInit, EntityType.ENTITY_PITFALL)

function mod:shadowPitFallUpdate(entity)
	if entity:GetData().skipAppear and entity.State == 2 then
		entity:GetSprite():SetFrame(10)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.shadowPitFallUpdate, EntityType.ENTITY_PITFALL)