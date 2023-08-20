local mod = BetterMonsters

local Settings = {
	NewHealth = 1000, -- Crazy 50 hp buff
	FetusCooldown = {60, 90},
	GutsCooldown = 45 -- Initial delay before starting
}

-- Example on how to add custom spawns: (variant and subtype can be left out to default it to 0)
-- table.insert( IRFitLivesSpawns.Fetus[1], {CoolMod.EpicEnemy, 21}, 69 )
IRFitLivesSpawns = {
	Fetus = {
		{ -- 100% - 75%
			{EntityType.ENTITY_MEMBRAIN, 1},
			{EntityType.ENTITY_OOB},
			{EntityType.ENTITY_GURGLING, 1},
		},
		{ -- 75% - 50%
			{EntityType.ENTITY_MONSTRO},
			{EntityType.ENTITY_DUKE},
			{EntityType.ENTITY_GEMINI},
		},
		{ -- 50% - 25%
			{EntityType.ENTITY_CHUB},
			{EntityType.ENTITY_GURDY_JR},
			{EntityType.ENTITY_POLYCEPHALUS},
		}
	},

	Guts = {
		{ -- 100% - 75%
			{EntityType.ENTITY_PARA_BITE},
			{EntityType.ENTITY_WALKINGBOIL},
			{EntityType.ENTITY_HOMUNCULUS},
		},
		{ -- 75% - 50%
			{EntityType.ENTITY_GLOBIN},
			{EntityType.ENTITY_BABY},
			{EntityType.ENTITY_VIS},
		},
		{ -- 50% - 25%
			{EntityType.ENTITY_LEECH},
			{EntityType.ENTITY_FRED},
			{EntityType.ENTITY_TUMOR},
		}
	}
}



function mod:itLivesInit(entity)
	-- Fetus
	if entity.Variant == 1 then
		entity.MaxHitPoints = Settings.NewHealth
		entity.HitPoints = entity.MaxHitPoints

		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity.TargetPosition = entity.Position

		entity:GetData().phase = 1
		entity:GetData().attackCounter = 1

		mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_ISAAC)


	-- Guts
	elseif entity.Variant == 10 then
		-- Get the parent's variant
		entity.SubType = entity.SpawnerVariant

		-- It Lives' guts
		if entity.SubType == 1 then
			entity:GetSprite():Load("gfx/078.010_it lives guts.anm2", true)
			entity.ProjectileCooldown = Settings.GutsCooldown

			if entity.SpawnerEntity then
				entity.SpawnerEntity.Child = entity
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.itLivesInit, EntityType.ENTITY_MOMS_HEART)

function mod:itLivesUpdate(entity)
	if entity.Variant == 1 or (entity.Variant == 10 and entity.SubType == 1) then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()
		local room = Game():GetRoom()

		-- Base projectile parameters
		local baseProjectileParams = ProjectileParams()
		baseProjectileParams.Scale = 1.5
		baseProjectileParams.BulletFlags = ProjectileFlags.HIT_ENEMIES
		baseProjectileParams.FallingSpeedModifier = 1
		baseProjectileParams.FallingAccelModifier = -0.1


		--[[ Fetus ]]--
		if entity.Variant == 1 then
			local animPrefix = math.max(1, data.phase - 2)

			-- Get the guts
			local guts = nil
			if entity.Child then
				guts = entity.Child:ToNPC()
			end


			--[[ Functions ]]--
			-- Reset variables for attacks
			local function resetVariables()
				entity.ProjectileCooldown = Settings.FetusCooldown[animPrefix]
				entity.I1 = 0
				entity.I2 = 0
				entity.StateFrame = 0
				entity.ProjectileDelay = 0
			end


			-- Choose an attack, don't repeat it this cycle if it's an enraged attack
			local function chooseAttack(group)
				local attack = mod:Random(1, 3)

				if group == "enraged" then
					local attacks = {1, 2, 3}
					if data.lastAttack then
						table.remove(attacks, data.lastAttack)
					end

					-- Don't do the Brimstone attack if the player is right under him
					local targetAngle = (target.Position - entity.Position):GetAngleDegrees()
					if attacks[1] == 1 and targetAngle > 40 and targetAngle < 140 then
						table.remove(attacks, 1)
					end

					attack = mod:RandomIndex(attacks)
					data.lastAttack = attack
				end

				-- Set state
				if attack == 1 then
					entity.State = NpcState.STATE_ATTACK
				elseif attack == 2 then
					entity.State = NpcState.STATE_ATTACK2
				elseif attack == 3 then
					entity.State = NpcState.STATE_ATTACK3
				end


				-- Set animation and other variables
				-- First group
				if group == "first" then
					-- Overlapping lines of shots
					if attack == 1 then
						sprite:Play(animPrefix .. "CryStart", true)

					-- Pulsating ring + stream of shots
					elseif attack == 2 then
						sprite:Play(animPrefix .. "SqueezeStart", true)
						entity.I2 = mod:Random(1)

					-- Opposite rotation shots
					elseif attack == 3 then
						sprite:Play(animPrefix .. "SqueezeStart", true)
					end


				-- Second group
				elseif group == "second" then
					-- Burst shot
					if attack == 1 then
						sprite:Play(animPrefix .. "Spit", true)

					-- Slam
					elseif attack == 2 then
						sprite:Play(animPrefix .. "Slam", true)

					-- Scream attack
					elseif attack == 3 then
						sprite:Play(animPrefix .. "SqueezeStart", true)
						entity.V1 = Vector(mod:Random(359), 0)
					end


				-- Enraged group
				elseif group == "enraged" then
					-- Brimstone + lines of shots
					if attack == 1 then
						sprite:Play(animPrefix .. "SqueezeStart", true)
						entity.I2 = mod:GetSign(target.Position.X > entity.Position.X)

						-- Tracers
						for i = 0, 3 do
							mod:QuickTracer(entity, 45 + i * 90, Vector.Zero, 15, 1, 2)
						end

					-- Slam
					elseif attack == 2 then
						sprite:Play(animPrefix .. "Slam", true)

					-- Pulsing rotating shots
					elseif attack == 3 then
						sprite:Play(animPrefix .. "CryStart", true)
					end
				end
			end


			-- Scream effects
			local function doTheRoar()
				mod:PlaySound(entity, SoundEffect.SOUND_MULTI_SCREAM)
				Game():MakeShockwave(entity.Position + Vector(0, 48), 0.02, 0.025, 15)
				Game():ShakeScreen(8)
			end


			-- Should this enemy keep him retracted and get killed by his spikes
			local function isValidEnemy(entity)
				if  entity:ToNPC() and entity:ToNPC():IsActiveEnemy(false)
				and entity.Type ~= EntityType.ENTITY_MOMS_HEART
				and not (entity.Type == EntityType.ENTITY_HOMUNCULUS and entity.Variant == 10)
				and not entity:IsDead()
				and entity:IsInvincible() == false
				and entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) == false then
					return true
				end
				return false
			end



			--[[ Always active ]]--
			-- Hide helper
			if sprite:IsEventTriggered("Hide") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				mod:PlaySound(nil, SoundEffect.SOUND_HEARTIN)

				if not sprite:IsPlaying(animPrefix .. "Slam") then
					entity:RemoveStatusEffects()
				end

			-- Come down helper
			elseif sprite:IsEventTriggered("ComeDown") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
				mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT)

				if not sprite:IsPlaying(animPrefix .. "Slam") then
					mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_ISAAC)
					Game():ShakeScreen(8)
				end
			end

			-- Squeeze sound helper
			if sprite:IsFinished(animPrefix .. "SqueezeStart") then
				mod:PlaySound(entity, SoundEffect.SOUND_FAT_WIGGLE, 1.1)
			end

			-- Scream helper
			if sprite:IsFinished(animPrefix .. "CryStart") then
				doTheRoar()
			end

			-- Slam effects
			if sprite:IsEventTriggered("Slam") then
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity)
				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.1)
				mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1.1)
				Game():ShakeScreen(14)
				Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)
			end


			-- Always stay in the spawn position
			entity.Velocity = Vector.Zero
			entity.Position = entity.TargetPosition

			if entity:HasEntityFlags(EntityFlag.FLAG_KNOCKED_BACK) then
				entity:ClearEntityFlags(EntityFlag.FLAG_KNOCKED_BACK)
			end


			-- Transition to next phase
			local quarterHp = (entity.MaxHitPoints / 4)

			if data.phase < 4 and entity.HitPoints <= entity.MaxHitPoints - (quarterHp * data.phase) then
				data.phase = data.phase + 1

				-- Enrage
				if data.phase == 4 and not data.wasDelirium then
					entity.HitPoints = quarterHp

					-- Come down first if retracted
					if entity.State == NpcState.STATE_JUMP or entity.State == NpcState.STATE_SUMMON2 then
						entity.State = NpcState.STATE_STOMP
						sprite:Play("1HideBack", true)

					elseif entity.State ~= NpcState.STATE_STOMP and entity.State ~= NpcState.STATE_IDLE then
						entity.State = NpcState.STATE_IDLE
					end
				end
			end


			-- Check if he can come down or not
			local canComeDown = true

			for i, enemy in pairs(Isaac.GetRoomEntities()) do
				if isValidEnemy(enemy) == true or (enemy.Type == EntityType.ENTITY_PROJECTILE and enemy.Variant == ProjectileVariant.PROJECTILE_MEAT) then
					canComeDown = false
					break
				end
			end


			-- Heartbeat effect
			if entity:IsFrame(50 - math.min(3, data.phase - 1) * 10, 0) then
				local sound = SoundEffect.SOUND_HEARTBEAT
				if data.phase >= 3 then
					sound = SoundEffect.SOUND_HEARTBEAT_FASTER
				end
				mod:PlaySound(nil, sound, 0.85)
			end


			-- Make other enemies not go near him
			if entity.State ~= NpcState.STATE_SUMMON2 and entity.State ~= NpcState.STATE_SUMMON3 then
				for i = -1, 1 do
					for j = -1, 1 do
						local gridPos = entity.Position + Vector(i * 40, j * 40)
						local grid = room:GetGridIndex(gridPos)
						room:SetGridPath(grid, 900)
					end
				end
			end



			--[[ Idle ]]--
			if entity.State == NpcState.STATE_IDLE then
				-- Spawn Homunculi
				if not data.homunculiSpawned then
					for i = -1, 1, 2 do
						Isaac.Spawn(EntityType.ENTITY_HOMUNCULUS, 0, 0, Vector(entity.Position.X + i * 140, room:GetTopLeftPos().Y + 40), Vector.Zero, entity)
					end
					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)

					data.homunculiSpawned = true
					entity.ProjectileCooldown = Settings.FetusCooldown[1]

					-- Delirium fix
					if data.wasDelirium then
						data.phase = 5 - math.ceil(entity.HitPoints / (entity.MaxHitPoints / 4))
					end
				end


				mod:LoopingAnim(sprite, animPrefix .. "Idle")

				-- Attack
				if entity.ProjectileCooldown <= 0 then
					resetVariables()

					-- FUCK YOU FUCK YOU FUCK YOU
					if data.wasDelirium then
						data.attackCounter = 3 - (animPrefix - 1)
					end


					-- Enraged
					if data.phase == 4 then
						-- Retract
						if data.attackCounter == 3 then
							entity.State = NpcState.STATE_JUMP
							sprite:Play(animPrefix .. "Hide", true)

						-- Attack
						else
							chooseAttack("enraged")
						end


					-- Not enraged
					else
						-- First attack
						if data.attackCounter == 1 then
							chooseAttack("first")

						-- Summon enemies
						elseif data.attackCounter == 2 then
							guts.State = NpcState.STATE_SUMMON
							guts:GetSprite():Play("ShootBoth", true)

						-- Second attack
						elseif data.attackCounter == 3 then
							chooseAttack("second")

						-- Summon harder enemies then retract
						elseif data.attackCounter == 4 then
							entity.State = NpcState.STATE_SUMMON
							sprite:Play(animPrefix .. "Spawn", true)
						end
					end


					-- Perform attacks in the same order
					if (data.enraged and data.attackCounter >= 3) or data.attackCounter >= 4 then
						data.attackCounter = 1
						data.lastAttack = nil
					else
						data.attackCounter = data.attackCounter + 1
					end

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end


				-- Enrage
				if data.phase == 4 and not data.enraged and not data.wasDelirium then
					entity.State = NpcState.STATE_SPECIAL
					sprite:Play("Angry", true)
					data.enraged = true

					resetVariables()
					data.attackCounter = 1

					-- Summon spikes to kill all enemies
					for i, enemy in pairs(Isaac.GetRoomEntities()) do
						if isValidEnemy(enemy) == true then
							Isaac.Spawn(IRFentities.Type, IRFentities.GiantSpike, 0, enemy.Position, Vector.Zero, entity).Target = enemy
						end
					end
					
					-- Bursting bubble fix
					if data.burstProjectiles then
						for i, bubble in pairs(data.burstProjectiles) do
							bubble:Kill()
						end
						data.burstProjectiles = nil
					end
				end



			--[[ Overlapping lines of shots / Burst shot / Brimstone + lines of shots ]]--
			elseif entity.State == NpcState.STATE_ATTACK then
				-- Brimstone + lines of shots
				if data.phase == 4 then
					-- Start
					if entity.StateFrame == 0 then
						if sprite:IsFinished() then
							entity.StateFrame = 1
						end

					-- Loop
					elseif entity.StateFrame == 1 then
						mod:LoopingAnim(sprite, animPrefix .. "SqueezeLoop")

						if entity.ProjectileDelay <= 0 then
							for i = 0, 3 do
								-- Create the lasers
								if entity.I1 == 0 then
									local angle = 45 + i * 90
									local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position - Vector(0, 15), angle, 25, Vector.Zero, entity), entity}
									laser_ent_pair.laser:SetActiveRotation(10, entity.I2 * 180, entity.I2 * 1.4, -1)
								end

								local params = baseProjectileParams
								params.FallingAccelModifier = -0.12
								entity:FireProjectiles(entity.Position, Vector.FromAngle(i * 90 + -entity.I2 * entity.I1 * 18):Resized(4.5), 0, baseProjectileParams)
							end

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 0.9)
							mod:ShootEffect(entity, 3, Vector(0, -30), Color.Default, 1, true)

							entity.I1 = entity.I1 + 1
							entity.ProjectileDelay = 10

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

						if entity.I1 >= 13 then
							entity.StateFrame = 2
							sprite:Play(animPrefix .. "SqueezeEnd", true)
						end

					-- Stop
					elseif entity.StateFrame == 2 then
						if sprite:IsFinished() then
							entity.State = NpcState.STATE_IDLE
						end
					end


				-- Overlapping lines of shots
				elseif data.attackCounter == 2 then
					-- Start
					if entity.StateFrame == 0 then
						if sprite:IsFinished() then
							entity.StateFrame = 1
						end

					-- Loop
					elseif entity.StateFrame == 1 then
						mod:LoopingAnim(sprite, animPrefix .. "CryLoop")

						if entity.ProjectileDelay <= 0 then
							for i = 0, 1 do
								local params = baseProjectileParams
								params.CircleAngle = 0 + (i * 0.8) + (mod:GetSign(i) * entity.I1 * 0.175)
								entity:FireProjectiles(entity.Position, Vector(7, 4), 9, params)
							end

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 0.9)
							mod:ShootEffect(entity, 3, Vector(0, -36), Color.Default, 1, true)

							entity.I1 = entity.I1 + 1
							entity.ProjectileDelay = 8 - data.phase

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

						if entity.I1 >= 8 then
							entity.StateFrame = 2
							sprite:Play(animPrefix .. "CryEnd", true)
						end

					-- Stop
					elseif entity.StateFrame == 2 then
						if sprite:IsFinished() then
							entity.State = NpcState.STATE_IDLE
						end
					end


				-- Burst shot
				elseif data.attackCounter == 4 then
					if sprite:IsEventTriggered("Shoot") then
						local params = ProjectileParams()
						params.BulletFlags = (ProjectileFlags.ACID_RED | ProjectileFlags.RED_CREEP | ProjectileFlags.BURST8)
						params.Scale = 2.75
						mod:FireProjectiles(entity, entity.Position, (target.Position - entity.Position):Resized(12), 0, params, Color.Default)

						mod:PlaySound(entity, SoundEffect.SOUND_SHAKEY_KID_ROAR)
						mod:PlaySound(entity, SoundEffect.SOUND_LITTLE_SPIT, 1.1, 0.95)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end
				end



			--[[ Pulsating ring + stream of shots / Slam / Slam ]]--
			elseif entity.State == NpcState.STATE_ATTACK2 then
				-- Slam
				if data.phase == 4 then
					if sprite:IsEventTriggered("Hide") then
						mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT)

					elseif sprite:IsEventTriggered("Slam") then
						local params = baseProjectileParams
						local offset = mod:Random(10, 100) * 0.01

						-- Regular shots
						params.CircleAngle = offset
						entity:FireProjectiles(entity.Position, Vector(9, 8), 9, params)

						-- Bouncing shots
						params.CircleAngle = offset + 0.4
						params.FallingAccelModifier = -0.088
						params.BulletFlags = params.BulletFlags + ProjectileFlags.BOUNCE

						for i, projectile in pairs(mod:FireProjectiles(entity, entity.Position, Vector(7, 8), 9, params)) do
							mod:QuickTrail(projectile, 0.09, Color(1,0.25,0.25, 1), projectile.Scale * 1.6)
						end
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end


				-- Pulsating ring + stream of shots
				elseif data.attackCounter == 2 then
					-- Start
					if entity.StateFrame == 0 then
						if sprite:IsFinished() then
							entity.StateFrame = 1
						end

					-- Loop
					elseif entity.StateFrame == 1 then
						mod:LoopingAnim(sprite, animPrefix .. "SqueezeLoop")

						if entity.ProjectileDelay <= 0 then
							entity:FireProjectiles(entity.Position, Vector(7, 4), 7, baseProjectileParams)
							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 0.9)
							mod:ShootEffect(entity, 3, Vector(0, -30), Color.Default, 1, true)

							-- Pulsating shots
							if entity.I1 % 6 == 0 then
								local params = baseProjectileParams
								params.Scale = 1.75

								-- Get curve direction
								local curveDir = ProjectileFlags.CURVE_LEFT
								if entity.I2 % 2 == 1 then
									curveDir = ProjectileFlags.CURVE_RIGHT
								end
								params.BulletFlags = params.BulletFlags + (ProjectileFlags.SINE_VELOCITY | curveDir)

								entity:FireProjectiles(entity.Position, Vector(4, 13), 9, params)
								mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.9)
								entity.I2 = entity.I2 + 1
							end

							entity.I1 = entity.I1 + 1
							entity.ProjectileDelay = 8 - data.phase

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

						if entity.I1 >= 21 then
							entity.StateFrame = 2
							sprite:Play(animPrefix .. "SqueezeEnd", true)
						end

					-- Stop
					elseif entity.StateFrame == 2 then
						if sprite:IsFinished() then
							entity.State = NpcState.STATE_IDLE
						end
					end


				-- Slam
				elseif data.attackCounter == 4 then
					if sprite:IsEventTriggered("Hide") then
						mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT)

					-- Falling shots
					elseif sprite:IsEventTriggered("Slam") or sprite:IsEventTriggered("Shoot") then
						-- Get position
						local pos = target.Position

						if entity.I1 == 0 then
							entity.V1 = (target.Position - entity.Position):Normalized()
						else
							local angle = mod:GetSign(entity.I1 % 2) * mod:Random(90, 150)
							local distance = mod:Random(60, 160)
							pos = entity.Position + entity.V1:Rotated(angle):Resized(distance)
						end

						pos = room:GetClampedPosition(pos, 20)

						-- Target
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TARGET, 0, pos, Vector.Zero, entity):ToEffect().Timeout = 30

						local params = ProjectileParams()
						params.HeightModifier = -500
						params.FallingAccelModifier = 2.5
						params.BulletFlags = ProjectileFlags.EXPLODE
						params.Scale = 1.75
						mod:FireProjectiles(entity, pos, Vector.Zero, 0, params, Color.Default)

						entity.I1 = entity.I1 + 1
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end
				end



			--[[ Opposite rotation shots / Scream attack / Pulsating rotating shots ]]--
			elseif entity.State == NpcState.STATE_ATTACK3 then
				-- Pulsating rotating shots
				if data.phase == 4 then
					-- Start
					if entity.StateFrame == 0 then
						if sprite:IsFinished() then
							entity.StateFrame = 1
						end

					-- Loop
					elseif entity.StateFrame == 1 then
						mod:LoopingAnim(sprite, animPrefix .. "CryLoop")

						if entity.ProjectileDelay <= 0 then
							local params = baseProjectileParams
							params.BulletFlags = params.BulletFlags + ProjectileFlags.SINE_VELOCITY

							if entity.I1 % 2 == 0 then
								params.BulletFlags = params.BulletFlags + ProjectileFlags.CURVE_LEFT
							else
								params.BulletFlags = params.BulletFlags + ProjectileFlags.CURVE_RIGHT
							end
							params.CircleAngle = 0 + entity.I1 * 0.3
							entity:FireProjectiles(entity.Position, Vector(4, 8), 9, params)

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 0.9)
							mod:ShootEffect(entity, 3, Vector(0, -36), Color.Default, 1, true)

							entity.I1 = entity.I1 + 1
							entity.ProjectileDelay = 13

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

						if entity.I1 >= 8 then
							entity.StateFrame = 2
							sprite:Play(animPrefix .. "CryEnd", true)
						end

					-- Stop
					elseif entity.StateFrame == 2 then
						if sprite:IsFinished() then
							entity.State = NpcState.STATE_IDLE
						end
					end


				-- Opposite rotation shots
				elseif data.attackCounter == 2 then
					-- Start
					if entity.StateFrame == 0 then
						if sprite:IsFinished() then
							entity.StateFrame = 1
						end

					-- Loop
					elseif entity.StateFrame == 1 then
						mod:LoopingAnim(sprite, animPrefix .. "SqueezeLoop")

						if entity.ProjectileDelay <= 0 then
							local params = baseProjectileParams
							params.CircleAngle = 0 + entity.I1 * 0.3
							entity:FireProjectiles(entity.Position, Vector(6, 5), 9, params)

							params.CircleAngle = 0 - entity.I1 * 0.3
							entity:FireProjectiles(entity.Position, Vector(3, 5), 9, params)

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 0.9)
							mod:ShootEffect(entity, 3, Vector(0, -30), Color.Default, 1, true)

							entity.I1 = entity.I1 + 1
							entity.ProjectileDelay = 11 - data.phase

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

						if entity.I1 >= 15 then
							entity.StateFrame = 2
							sprite:Play(animPrefix .. "SqueezeEnd", true)
						end

					-- Stop
					elseif entity.StateFrame == 2 then
						if sprite:IsFinished() then
							entity.State = NpcState.STATE_IDLE
						end
					end


				-- Scream attack
				elseif data.attackCounter == 4 then
					-- Start
					if entity.StateFrame == 0 then
						if sprite:IsFinished() then
							entity.StateFrame = 1
							entity.I2 = 20
							data.stoppedProjectiles = {}
						end

					-- Loop
					elseif entity.StateFrame == 1 then
						mod:LoopingAnim(sprite, animPrefix .. "SqueezeLoop")

						-- Create 6 bursting bubbles
						if entity.I1 < 5 then
							if entity.ProjectileDelay <= 0 then
								local params = ProjectileParams()
								params.Scale = 1.5
								params.BulletFlags = (ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
								params.ChangeTimeout = 9999
								params.ChangeVelocity = 11
								params.Acceleration = 1.1
								params.FallingAccelModifier = -0.175

								local projectiles = {}
								for i = 0, 3 do
									local projectile = mod:FireProjectiles(entity, entity.Position, Vector.FromAngle(entity.V1.X + i * 90 + entity.I1 * 18):Resized(6), 0, params)
									table.insert(projectiles, projectile)
								end
								table.insert(data.stoppedProjectiles, projectiles)

								mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 0.9)
								mod:ShootEffect(entity, 3, Vector(0, -30), Color.Default, 1, true)

								entity.I1 = entity.I1 + 1
								entity.ProjectileDelay = 1

							else
								entity.ProjectileDelay = entity.ProjectileDelay - 1
							end

						else
							-- Delay before the scream
							if entity.I2 <= 0 then
								entity.StateFrame = 2
								sprite:Play(animPrefix .. "CryStart", true)
								sprite:SetFrame(2)

							else
								entity.I2 = entity.I2 - 1
							end
						end

					-- Scream
					elseif entity.StateFrame == 2 then
						if sprite:IsFinished() then
							entity.StateFrame = 3
							entity.I2 = 20
						end

					-- Scream Loop
					elseif entity.StateFrame == 3 then
						mod:LoopingAnim(sprite, animPrefix .. "CryLoop")

						-- Shoot the projectiles
						if #data.stoppedProjectiles >= 1 then
							if entity.ProjectileDelay <= 0 then
								for i, projectile in pairs(data.stoppedProjectiles[1]) do
									projectile.ChangeTimeout = 0
									projectile.Velocity = (target.Position - projectile.Position):Resized(11)

									-- Effects
									local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 5, projectile.Position, Vector.Zero, entity):GetSprite()
									effect.Offset = Vector(projectile.PositionOffset.X, projectile.Height * 0.5)
									effect.Color = Color(1,1,1, 0.75)
									effect.Scale = Vector(0.75, 0.75)
								end

								mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

								table.remove(data.stoppedProjectiles, 1)
								entity.ProjectileDelay = 6

							else
								entity.ProjectileDelay = entity.ProjectileDelay - 1
							end

						else
							-- Delay before stopping
							if entity.I2 <= 0 then
								entity.StateFrame = 4
								sprite:Play(animPrefix .. "CryEnd", true)
								data.stoppedProjectiles = nil

							else
								entity.I2 = entity.I2 - 1
							end
						end

					-- Stop
					elseif entity.StateFrame == 4 then
						if sprite:IsFinished() then
							entity.State = NpcState.STATE_IDLE
						end
					end
				end



			--[[ Retract ]]--
			elseif entity.State == NpcState.STATE_JUMP then
				if sprite:IsFinished() then
					if data.phase == 4 then
						entity.State = NpcState.STATE_SUMMON3
						entity.I2 = mod:RandomSign()
					else
						entity.State = NpcState.STATE_SUMMON2
					end
				end

			--[[ Come down ]]--
			elseif entity.State == NpcState.STATE_STOMP then
				if sprite:IsEventTriggered("ComeDown") then
					-- Hurt the player if they're under him
					entity.CollisionDamage = 2

					-- Stop the guts from attacking
					guts.ProjectileCooldown = Settings.GutsCooldown
					if guts.State == NpcState.STATE_ATTACK and guts.StateFrame == 1 then
						guts.StateFrame = 2
						guts:GetSprite():Play("ShootBothEnd", true)
					else
						guts.State = NpcState.STATE_IDLE
					end

				elseif sprite:WasEventTriggered("ComeDown") then
					entity.CollisionDamage = 0
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end



			--[[ Summon ]]--
			elseif entity.State == NpcState.STATE_SUMMON then
				if sprite:IsEventTriggered("Spawn") then
					local spawnGroup = IRFitLivesSpawns.Fetus[data.phase]

					local selectedSpawn = mod:RandomIndex(spawnGroup)
					local type    = selectedSpawn[1]
					local variant = selectedSpawn[2] or 0
					local subtype = selectedSpawn[3] or 500 -- It's 500 so bosses don't spawn as champions

					-- For Gurglings
					if type == EntityType.ENTITY_GURGLING then
						for i = -1, 1, 2 do
							Isaac.Spawn(type, variant, subtype, entity.Position + Vector(i * 30, 40), Vector.Zero, entity).SubType = 0 -- They don't work properly if their subtype is higher than 2
						end

					-- For Chub
					elseif type == EntityType.ENTITY_CHUB then
						for i = -1, 1 do
							Isaac.Spawn(type, variant, subtype, entity.Position + Vector(i * 30, 40), Vector.Zero, entity)
						end

					else
						Isaac.Spawn(type, variant, subtype, entity.Position + Vector(0, 40), Vector.Zero, entity)
					end

					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
					mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT)
					mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_EVILLAUGH)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_JUMP
					sprite:Play(animPrefix .. "Hide", true)
				end

			--[[ Retracted ]]--
			elseif entity.State == NpcState.STATE_SUMMON2 then
				-- Laugh
				if entity.I2 == 1 and sprite:IsFinished() then
					entity.I2 = 0
				elseif entity.I2 ~= 1 then
					mod:LoopingAnim(sprite, animPrefix .. "HideIdle")
				end

				-- Come down if all enemies are dead
				if canComeDown == true then
					-- Delay before coming down
					if entity.StateFrame <= 0 then
						entity.State = NpcState.STATE_STOMP
						sprite:Play(animPrefix .. "HideBack", true)

					else
						entity.StateFrame = entity.StateFrame - 1
					end

				else
					entity.StateFrame = 20
				end



			--[[ Enrage ]]--
			elseif entity.State == NpcState.STATE_SPECIAL then
				-- Effects
				if sprite:IsEventTriggered("BloodStart") then
					doTheRoar()
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_JUMP
					sprite:Play(animPrefix .. "Hide", true)
				end

			--[[ Blood cell attack ]]--
			elseif entity.State == NpcState.STATE_SUMMON3 then
				mod:LoopingAnim(sprite, animPrefix .. "HideIdle")

				if entity.I1 < 10 then
					-- Come down delay
					entity.StateFrame = 90

					if entity.ProjectileDelay <= 0 then
						-- Get movement direction
						local direction = 90 + entity.I2 * 90

						-- Left (default)
						local basePos = Vector(room:GetTopLeftPos().X - 140, room:GetCenterPos().Y - 20)
						-- Right
						if entity.I2 == 1 then
							basePos = Vector(room:GetBottomRightPos().X + 140, room:GetCenterPos().Y + 20)
						end


						local params = ProjectileParams()
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.18
						params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.WIGGLE)

						local burstChoice = mod:Random(-1, 1)


						for i = -1, 1 do
							local pos = basePos + Vector.FromAngle(direction):Rotated(90):Resized(i * 100 + (entity.I1 % 2) * 40)

							local shot = mod:FireProjectiles(entity, pos, Vector.FromAngle(direction):Resized(6.5), 0, params)
							shot.Scale = 1.5
							shot:GetSprite():Load("gfx/blood cell projectile.anm2", true)

							-- Bursting cell
							if entity.I1 % 3 == 0 and i == burstChoice then
								shot:GetData().splitTimer = mod:Random(20, 60)
								shot:GetSprite():Play("IdleBurst", true)

							-- Regular cell
							else
								shot:GetSprite():Play("Idle", true)
							end
						end


						entity.ProjectileDelay = 20
						entity.I1 = entity.I1 + 1

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end


				-- Come down after all the lines have spawned
				elseif canComeDown == true then
					-- Delay before coming down
					if entity.StateFrame <= 0 then
						entity.State = NpcState.STATE_STOMP
						sprite:Play(animPrefix .. "HideBack", true)

					else
						entity.StateFrame = entity.StateFrame - 1
					end
				end
			end





		--[[ Guts ]]--
		elseif entity.Variant == 10 then
			-- Die without a parent
			if not entity.Parent or entity.Parent:IsDead() then
				if data.wasDelirium then
					entity:Remove()
				else
					entity.State = NpcState.STATE_DEATH
					sprite:Play("Death", true)
				end

			else
				local fetus = entity.Parent:ToNPC()

				-- Delirium fix
				data.wasDelirium = fetus:GetData().wasDelirium

				if entity.FrameCount <= 1 and data.wasDelirium then
					sprite:Load("gfx/078.010_it lives guts.anm2", true)
					for i = 0, sprite:GetLayerCount() do
						sprite:ReplaceSpritesheet(i, "gfx/bosses/afterbirthplus/deliriumforms/classic/boss_78_it lives guts.png")
					end
					sprite:LoadGraphics()
				end


				-- Get shoot positions
				local function getShootPos(side)
					local position = Vector(entity.Position.X, room:GetTopLeftPos().Y + 36)
					local sign = mod:GetSign(side > 0)
					return position + sign * Vector(134, 0)
				end

				-- Create shoot effects in the correct position
				local function doShootEffect(pos)
					return mod:ShootEffect(entity, 2, (pos + Vector(0, -20) - entity.Position) * 0.65)
				end

				-- Make enemies not go near the holes
				for side = -1, 1, 2 do
					for i = 0, 1 do
						for j = 0, 1 do
							local startPos = getShootPos(side) + Vector(0, -20)
							local gridPos = startPos + Vector(i * side * 40, j * 40)
							local grid = room:GetGridIndex(gridPos)
							room:SetGridPath(grid, 900)
						end
					end
				end


				--[[ Idle ]]--
				if entity.State == NpcState.STATE_IDLE then
					mod:LoopingAnim(sprite, "Idle")

					if fetus.State == NpcState.STATE_SUMMON2 then
						if entity.ProjectileCooldown <= 0 then
							entity.I1 = 0
							entity.StateFrame = 0
							entity.ProjectileDelay = 0

							local attack = mod:Random(1, 3)

							-- Rotating shots
							if attack == 1 then
								entity.State = NpcState.STATE_ATTACK
								sprite:Play("ShootBothStart", true)

							-- Half rings of shots
							elseif attack == 2 then
								entity.State = NpcState.STATE_ATTACK2

							-- Aimed shots
							elseif attack == 3 then
								entity.State = NpcState.STATE_ATTACK3
							end

						else
							entity.ProjectileCooldown = entity.ProjectileCooldown - 1
						end
					end



				--[[ Summon ]]--
				elseif entity.State == NpcState.STATE_SUMMON then
					if sprite:IsEventTriggered("Shoot") then
						local spawnGroup = IRFitLivesSpawns.Guts[fetus:GetData().phase]
						local selectedSpawn = mod:RandomIndex(spawnGroup)

						for i = -1, 1, 2 do
							Isaac.Spawn(selectedSpawn[1], selectedSpawn[2] or 0, selectedSpawn[3] or 0, getShootPos(i), Vector.Zero, fetus)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Rotating shots ]]--
				elseif entity.State == NpcState.STATE_ATTACK then
					-- Start
					if entity.StateFrame == 0 then
						if sprite:IsFinished() then
							entity.StateFrame = 1
						end

					-- Loop
					elseif entity.StateFrame == 1 then
						mod:LoopingAnim(sprite, "ShootBothLoop")

						if entity.ProjectileDelay <= 0 then
							local params = baseProjectileParams

							for i = -1, 1, 2 do
								local pos = getShootPos(i)
								params.CircleAngle = 0 + i * entity.I1 * 0.3
								fetus:FireProjectiles(pos, Vector(5, 2), 9, params)
								doShootEffect(pos)
							end

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

							entity.I1 = entity.I1 + 1
							entity.ProjectileDelay = 18

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

					-- Stop
					elseif entity.StateFrame == 2 then
						if sprite:IsFinished() then
							entity.State = NpcState.STATE_IDLE
						end
					end



				--[[ Half rings of shots ]]--
				elseif entity.State == NpcState.STATE_ATTACK2 then
					-- Cooldown
					if entity.StateFrame == 0 then
						mod:LoopingAnim(sprite, "Idle")

						if entity.ProjectileDelay <= 0 then
							entity.StateFrame = 1

							-- Switch sides
							local side = "Left"
							if entity.I1 % 2 ~= 0 then
								side = "Right"
							end
							sprite:Play("Shoot" .. side, true)

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

					-- Shoot
					elseif entity.StateFrame == 1 then
						if sprite:IsEventTriggered("Shoot") then
							local params = baseProjectileParams
							params.FallingAccelModifier = -0.16

							local pos = getShootPos(entity.I1 % 2)
							for i = 0, 5 do
								fetus:FireProjectiles(pos, Vector.FromAngle(20 + i * 28):Resized(4), 0, params)
							end

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)
							doShootEffect(pos)

							entity.I1 = entity.I1 + 1
						end

						if sprite:IsFinished() then
							entity.StateFrame = 0
							entity.ProjectileDelay = 22
						end
					end



				--[[ Aimed shots ]]--
				elseif entity.State == NpcState.STATE_ATTACK3 then
					-- Cooldown
					if entity.StateFrame == 0 then
						mod:LoopingAnim(sprite, "Idle")

						if entity.ProjectileDelay <= 0 then
							entity.StateFrame = 1
							sprite:Play("ShootBoth", true)

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

					-- Shoot
					elseif entity.StateFrame == 1 then
						if sprite:IsEventTriggered("Shoot") then
							local params = baseProjectileParams
							params.FallingAccelModifier = -0.14
							params.Scale = 1.75

							for i = -1, 1, 2 do
								local pos = getShootPos(i)
								fetus:FireProjectiles(pos, (fetus:GetPlayerTarget().Position - pos):Resized(6.5), 0, params)
								doShootEffect(pos)
							end

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

							entity.I1 = entity.I1 + 1
						end

						if sprite:IsFinished() then
							entity.StateFrame = 0
							entity.ProjectileDelay = 14
						end
					end
				end
			end
		end


		if entity.FrameCount > 1 and not entity:HasMortalDamage() then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.itLivesUpdate, EntityType.ENTITY_MOMS_HEART)

function mod:itLivesDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 1 then
		-- Don't take damage from his spawns
		if damageSource.SpawnerType == target.Type then
			return false

		-- Grunt on high damage (like Mom's Heart)
		elseif damageAmount >= 40 then
			mod:PlaySound(target, SoundEffect.SOUND_MOM_VOX_FILTERED_HURT, 1, 1, 40)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.itLivesDMG, EntityType.ENTITY_MOMS_HEART)

function mod:itLivesCollide(entity, target, bool)
	if entity.Variant == 1 and target.SpawnerType == entity.Type or (target.SpawnerEntity and target.SpawnerEntity.SpawnerType == entity.Type) then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.itLivesCollide, EntityType.ENTITY_MOMS_HEART)



-- Laugh if the player gets hit while retreated
function mod:itLivesHit(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	-- Only if the damage was done by an enemy
	if damageSource.Entity and (damageSource.Entity:ToNPC() or (damageSource.Entity.SpawnerEntity and damageSource.Entity.SpawnerEntity:ToNPC())) then
		for i, itLives in pairs(Isaac.FindByType(EntityType.ENTITY_MOMS_HEART, 1, -1, false, false)) do
			if itLives:ToNPC().State == NpcState.STATE_SUMMON2 then
				itLives:ToNPC().I2 = 1
				itLives:GetSprite():Play("1HideHappy", true)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.itLivesHit, EntityType.ENTITY_PLAYER)



-- Projectiles
function mod:itLivesProjectileUpdate(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_MOMS_HEART and projectile.SpawnerVariant == 1 then
		local data = projectile:GetData()

		-- Burst projectile fix
		if projectile:HasProjectileFlags(ProjectileFlags.ACID_RED | ProjectileFlags.RED_CREEP) and not projectile:HasProjectileFlags(ProjectileFlags.BURST8) then
			projectile:ClearProjectileFlags(ProjectileFlags.ACID_RED | ProjectileFlags.RED_CREEP)


		-- Bursting cell
		elseif data.splitTimer then
			if data.splitTimer <= 0 then
				local sprite = projectile:GetSprite()

				if sprite:IsPlaying("IdleBurst") then
					sprite:Play("Burst", true)

				elseif sprite:IsFinished() then
					projectile:ClearProjectileFlags(ProjectileFlags.WIGGLE)
					projectile:AddProjectileFlags(ProjectileFlags.BURST8)
					projectile:Die()
				end

			else
				data.splitTimer = data.splitTimer - 1
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.itLivesProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)