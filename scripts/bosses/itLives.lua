local mod = BetterMonsters

local Settings = {
	HomunculusHealth = 50,
	FetusCooldown = 45,
	GutsCooldown = 45,
	SlamScreenShake = 14
}

IRFitLivesSpawns = {
	Fetus = {
		{ -- 100% - 75%
			{EntityType.ENTITY_OOB, 0},
			{EntityType.ENTITY_MONSTRO, 0},
			{EntityType.ENTITY_GEMINI, 0},
		},
		{ -- 75% - 50%
			{EntityType.ENTITY_COHORT, 0},
			{EntityType.ENTITY_FISTULA_BIG, 0},
			{EntityType.ENTITY_GURDY_JR, 0},
		},
		{ -- 50% - 25%
			{EntityType.ENTITY_ADULT_LEECH, 0},
			{EntityType.ENTITY_CHUB, 0},
			{EntityType.ENTITY_POLYCEPHALUS, 0},
		}
	},

	Guts = {
		{ -- 100% - 75%
			{EntityType.ENTITY_PARA_BITE, 0},
			{EntityType.ENTITY_WALKINGBOIL, 0},
			{EntityType.ENTITY_HOMUNCULUS, 0},
		},
		{ -- 75% - 50%
			{EntityType.ENTITY_VIS, 2},
			{EntityType.ENTITY_FISTULOID, 0},
			{EntityType.ENTITY_FACELESS, 0},
		},
		{ -- 50% - 25%
			{EntityType.ENTITY_LEECH, 0},
			{EntityType.ENTITY_TUMOR, 0},
			{EntityType.ENTITY_FLESH_MOBILE_HOST, 0},
		}
	}
}



function mod:itLivesInit(entity)
	-- Fetus
	if entity.Variant == 1 then
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

		local spawnedEnemyCount = entity:GetAliveEnemyCount() - 2

		local baseProjectileParams = ProjectileParams()
		baseProjectileParams.Scale = 1.5
		baseProjectileParams.BulletFlags = ProjectileFlags.HIT_ENEMIES
		baseProjectileParams.FallingSpeedModifier = 1
		baseProjectileParams.FallingAccelModifier = -0.13


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
				entity.ProjectileCooldown = Settings.FetusCooldown
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
						entity.I2 = mod:RandomSign()

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

					-- Bursting bubbles
					elseif attack == 3 then
						sprite:Play(animPrefix .. "SqueezeStart", true)
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


			-- Slam effects
			local function slamEffects()
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity)
				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.1)
				mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1.1)
				Game():ShakeScreen(Settings.SlamScreenShake)
				Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)
			end


			-- Scream effects
			local function doTheRoar()
				mod:PlaySound(entity, SoundEffect.SOUND_MULTI_SCREAM)
				Game():MakeShockwave(entity.Position + Vector(0, 48), 0.02, 0.025, 15)
				Game():ShakeScreen(8)
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


			-- Always stay in the spawn position
			entity.Velocity = Vector.Zero
			entity.Position = entity.TargetPosition

			if entity:HasEntityFlags(EntityFlag.FLAG_KNOCKED_BACK) then
				entity:ClearEntityFlags(EntityFlag.FLAG_KNOCKED_BACK)
			end


			-- Transition to next phase
			local quarterHp = (entity.MaxHitPoints / 4)

			if entity.HitPoints <= entity.MaxHitPoints - (quarterHp * data.phase) then
				data.phase = data.phase + 1

				-- Enrage
				if data.phase == 4 then
					entity.HitPoints = quarterHp

					-- Come down first if retracted
					if entity.State == NpcState.STATE_JUMP or entity.State == NpcState.STATE_SUMMON2 then
						entity.State = NpcState.STATE_STOMP
						sprite:Play(animPrefix .. "HideBack", true)

					elseif entity.State ~= NpcState.STATE_STOMP and entity.State ~= NpcState.STATE_IDLE then
						entity.State = NpcState.STATE_IDLE
					end
				end
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
						local homo = Isaac.Spawn(EntityType.ENTITY_HOMUNCULUS, 0, 0, Vector(entity.Position.X + i * 140, room:GetTopLeftPos().Y + 40), Vector.Zero, entity)
						homo.MaxHitPoints = Settings.HomunculusHealth
						homo.HitPoints = homo.MaxHitPoints
					end
					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)

					data.homunculiSpawned = true
					entity.ProjectileCooldown = Settings.FetusCooldown
				end


				mod:LoopingAnim(sprite, animPrefix .. "Idle")

				-- Attack
				if entity.ProjectileCooldown <= 0 then
					resetVariables()

					-- Enraged
					if data.phase == 4 then
						-- First attack
						if data.attackCounter == 1 then
							chooseAttack("enraged")

						-- Second attack
						elseif data.attackCounter == 2 then
							chooseAttack("enraged")

						-- Retract
						elseif data.attackCounter == 3 then
							entity.State = NpcState.STATE_JUMP
							sprite:Play(animPrefix .. "Hide", true)
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
					if data.attackCounter >= 4 then
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
						if enemy:ToNPC() and enemy:IsVulnerableEnemy() and enemy.Type ~= EntityType.ENTITY_MOMS_HEART and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
							Isaac.Spawn(IRFentities.Type, IRFentities.GiantSpike, 0, enemy.Position, Vector.Zero, entity).Target = enemy
						end
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
									laser_ent_pair.laser:SetActiveRotation(10, entity.I2 * 180, entity.I2 * 1.5, -1)
								end

								entity:FireProjectiles(entity.Position, Vector.FromAngle(i * 90 + -entity.I2 * entity.I1 * 18):Resized(4.5), 0, baseProjectileParams)
							end

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 0.9)
							mod:ShootEffect(entity, 3, Vector(0, -30), Color.Default, 1, true)

							entity.I1 = entity.I1 + 1
							entity.ProjectileDelay = 7

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

						if entity.I1 >= 16 then
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
								entity:FireProjectiles(entity.Position, Vector(6, 4), 9, params)
							end

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 0.9)
							mod:ShootEffect(entity, 3, Vector(0, -36), Color.Default, 1, true)

							entity.I1 = entity.I1 + 1
							entity.ProjectileDelay = 4

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

						if entity.I1 >= 12 then
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
						entity:FireProjectiles(entity.Position, Vector(9, 12), 9, params)

						-- Bouncing shots
						params.CircleAngle = offset + 0.25
						params.FallingAccelModifier = -0.09
						params.BulletFlags = params.BulletFlags + ProjectileFlags.BOUNCE

						for i, projectile in pairs(mod:FireProjectiles(entity, entity.Position, Vector(7, 12), 9, params)) do
							mod:QuickTrail(projectile, 0.09, Color(1,0.25,0.25, 1), projectile.Scale * 1.6)
						end

						slamEffects()
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
							local params = baseProjectileParams
							params.CircleAngle = 0 + entity.I2 * entity.I1 * 0.2
							entity:FireProjectiles(entity.Position, Vector(7, 4), 9, params)

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 0.9)
							mod:ShootEffect(entity, 3, Vector(0, -30), Color.Default, 1, true)

							-- Pulsating shots
							if entity.I1 % 10 == 0 then
								params.Scale = 1.75
								params.BulletFlags = params.BulletFlags + ProjectileFlags.SINE_VELOCITY
								entity:FireProjectiles(entity.Position, Vector(3, 16), 9, params)
								mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.9)
							end

							entity.I1 = entity.I1 + 1
							entity.ProjectileDelay = 4

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

						if entity.I1 >= 30 then
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

					elseif sprite:IsEventTriggered("Slam") or sprite:IsEventTriggered("Shoot") then
						-- Crackwaves
						if sprite:IsEventTriggered("Slam") then
							for i = 0, 3 do
								local angle = 45 + i * 90
								Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACKWAVE, 2, entity.Position + Vector.FromAngle(angle):Resized(20), Vector.Zero, entity):ToEffect().Rotation = angle
							end

							slamEffects()
						end

						-- Falling shots
						-- Get position
						local pos = target.Position

						if entity.I1 == 0 then
							entity.V1 = (target.Position - entity.Position):Normalized()
						else
							local angle = mod:GetSign(entity.I1 % 2) * mod:Random(60, 120)
							local distance = mod:Random(60, 120)
							pos = entity.Position + entity.V1:Rotated(angle):Resized(distance)
						end

						pos = room:GetClampedPosition(pos, -10)

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



			--[[ Opposite rotation shots / Bursting bubbles / Pulsing rotating shots ]]--
			elseif entity.State == NpcState.STATE_ATTACK3 then
				-- Pulsing rotating shots
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
							entity.ProjectileDelay = 10

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

						if entity.I1 >= 12 then
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
							entity.ProjectileDelay = 8

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


				-- Bursting bubbles
				elseif data.attackCounter == 4 then
					-- Start
					if entity.StateFrame == 0 then
						if sprite:IsFinished() then
							entity.StateFrame = 1
							entity.I2 = 15
							data.burstProjectiles = {}
						end

					-- Loop
					elseif entity.StateFrame == 1 then
						mod:LoopingAnim(sprite, animPrefix .. "SqueezeLoop")

						-- Create 8 bursting bubbles
						if entity.I1 < 8 then
							if entity.ProjectileDelay <= 0 then
								local params = ProjectileParams()
								params.Scale = 2
								params.BulletFlags = (ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.CHANGE_VELOCITY_AFTER_TIMEOUT)
								params.ChangeTimeout = 9999
								params.ChangeFlags = ProjectileFlags.BURST
								params.ChangeVelocity = 10
								params.Acceleration = 1.1
								params.FallingAccelModifier = -0.175

								local projectile = mod:FireProjectiles(entity, entity.Position, mod:RandomVector(mod:Random(8, 11)), 0, params, Color.Default)
								table.insert(data.burstProjectiles, projectile)

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
							entity.I2 = 15
						end

					-- Scream Loop
					elseif entity.StateFrame == 3 then
						mod:LoopingAnim(sprite, animPrefix .. "CryLoop")

						-- Burst the projectiles
						if #data.burstProjectiles >= 1 then
							if entity:IsFrame(4, 0) then
								data.burstProjectiles[1].ChangeTimeout = 0
								table.remove(data.burstProjectiles, 1)
							end

						else
							-- Delay before stopping
							if entity.I2 <= 0 then
								entity.StateFrame = 4
								sprite:Play(animPrefix .. "CryEnd", true)
								data.burstProjectiles = nil

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
						entity.I2 = mod:Random(2)
					else
						entity.State = NpcState.STATE_SUMMON2
					end
				end

			--[[ Come down ]]--
			elseif entity.State == NpcState.STATE_STOMP then
				-- Hurt the player if they're under him
				if sprite:IsEventTriggered("ComeDown") then
					entity.CollisionDamage = 2
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

					-- For Chub
					if selectedSpawn[1] == EntityType.ENTITY_CHUB then
						for i = -1, 1 do
							Isaac.Spawn(selectedSpawn[1], selectedSpawn[2], 0, entity.Position + Vector(i * 30, 40), Vector.Zero, entity)
						end
					else
						Isaac.Spawn(selectedSpawn[1], selectedSpawn[2], 0, entity.Position + Vector(0, 40), Vector.Zero, entity)
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
				if spawnedEnemyCount <= 0 then
					-- Delay before coming down
					if entity.StateFrame <= 0 then
						entity.State = NpcState.STATE_STOMP
						sprite:Play(animPrefix .. "HideBack", true)

						guts.State = NpcState.STATE_IDLE
						guts.ProjectileCooldown = Settings.GutsCooldown

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

				-- Push other entities away
				if sprite:WasEventTriggered("BloodStart") and not sprite:WasEventTriggered("BloodStop") then
					for i, others in pairs(Isaac.GetRoomEntities()) do
						if others:ToNPC() or others:ToPlayer() or others:ToTear() then
							local strength = 0.5
							if others:ToTear() then
								strength = 1
							end

							others:AddVelocity((others.Position - entity.Position):Resized(strength))
						end
					end
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_JUMP
					sprite:Play(animPrefix .. "Hide", true)
				end

			--[[ Blood cell attack ]]--
			elseif entity.State == NpcState.STATE_SUMMON3 then
				mod:LoopingAnim(sprite, animPrefix .. "HideIdle")

				if entity.I1 < 16 then
					-- Come down delay
					if entity.I2 == 2 then
						entity.StateFrame = 60
					else
						entity.StateFrame = 100
					end

					if entity.ProjectileDelay <= 0 then
						-- Get blood cell movement direction
						-- Left (default)
						local iMin = -1
						local iMax = 1
						local distance = 100
						local basePos = Vector(room:GetTopLeftPos().X - 140, room:GetCenterPos().Y - 20)
						local direction = 0
						local popMin = 10
						local popMax = 60

						-- Right
						if entity.I2 == 1 then
							basePos = Vector(room:GetBottomRightPos().X + 140, room:GetCenterPos().Y + 20)
							direction = 180

						-- Down
						elseif entity.I2 == 2 then
							iMin = -2
							iMax = 2
							distance = 110
							basePos = Vector(room:GetCenterPos().X + 20, room:GetTopLeftPos().Y - 80)
							direction = 90
							popMin = 5
							popMax = 25
						end


						local params = ProjectileParams()
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.17
						params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.WIGGLE)

						local burstChoice = mod:Random(-1, 1)


						for i = iMin, iMax do
							local evenOrNot = entity.I1 % 2
							local pos = basePos + Vector.FromAngle(direction):Rotated(90):Resized(i * distance + evenOrNot * 40)

							local shot = mod:FireProjectiles(entity, pos, Vector.FromAngle(direction):Resized(7), 0, params)
							shot:GetSprite():Load("gfx/blood cell projectile.anm2", true)

							-- Bursting cell
							if evenOrNot == 0 and i == burstChoice then
								shot:GetData().splitTimer = mod:Random(popMin, popMax)
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
				elseif spawnedEnemyCount <= 0 then
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
				entity.State = NpcState.STATE_DEATH
				sprite:Play("Death", true)

			else
				local fetus = entity.Parent:ToNPC()


				-- Get shoot positions
				local function getShootPos(side)
					local position = Vector(entity.Position.X, room:GetTopLeftPos().Y + 40)
					local sign = mod:GetSign(side > 0)
					return position + sign * Vector(135, 0)
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
							entity.ProjectileCooldown = Settings.GutsCooldown
							entity.I1 = 0
							entity.I2 = 0
							entity.StateFrame = 0
							entity.ProjectileDelay = 0

							local attack = mod:Random(1, 5)

							-- Rotating shots
							if attack == 1 then
								entity.State = NpcState.STATE_ATTACK
								sprite:Play("ShootBothStart", true)
								entity.I2 = mod:RandomSign()

							-- Half rings of shots
							elseif attack == 2 then
								entity.State = NpcState.STATE_ATTACK2
								sprite:Play("ShootLeft", true)

							-- Pulsating shots
							elseif attack == 3 then
								entity.State = NpcState.STATE_ATTACK3
								sprite:Play("ShootBoth", true)

							-- Sweeping line of shots
							elseif attack == 4 then
								entity.State = NpcState.STATE_ATTACK4
								sprite:Play("ShootBothStart", true)

							-- Spreads of 5 shots
							elseif attack == 5 then
								entity.State = NpcState.STATE_ATTACK5
								sprite:Play("ShootLeft", true)
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
							Isaac.Spawn(selectedSpawn[1], selectedSpawn[2], 0, getShootPos(i), Vector.Zero, fetus)
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
								params.CircleAngle = 0 + entity.I2 * entity.I1 * 0.3
								fetus:FireProjectiles(pos, Vector(4, 4), 9, params)
								mod:ShootEffect(entity, 2, (pos + Vector(0, -20) - entity.Position) * 0.65)
							end

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

							entity.I1 = entity.I1 + 1
							entity.ProjectileDelay = 9

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

						if entity.I1 >= 8 then
							entity.StateFrame = 2
							sprite:Play("ShootBothEnd", true)
						end

					-- Stop
					elseif entity.StateFrame == 2 then
						if sprite:IsFinished() then
							entity.State = NpcState.STATE_IDLE
						end
					end



				--[[ Half rings of shots ]]--
				elseif entity.State == NpcState.STATE_ATTACK2 then
					if sprite:IsEventTriggered("Shoot") then
						local params = baseProjectileParams
						params.FallingAccelModifier = -0.16

						local pos = getShootPos(entity.I1 % 2)
						for i = 0, 5 do
							fetus:FireProjectiles(pos, Vector.FromAngle(20 + i * 28):Resized(4), 0, params)
						end

						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)
						mod:ShootEffect(entity, 2, (pos + Vector(0, -20) - entity.Position) * 0.65)

						entity.I1 = entity.I1 + 1
					end

					if sprite:IsFinished() then
						-- Do this 4 times
						if entity.I1 >= 4 then
							entity.State = NpcState.STATE_IDLE

						else
							-- Switch sides
							local side = "Left"
							if entity.I1 % 2 ~= 0 then
								side = "Right"
							end
							sprite:Play("Shoot" .. side, true)
						end
					end



				--[[ Pulsating shots ]]--
				elseif entity.State == NpcState.STATE_ATTACK3 then
					if sprite:IsEventTriggered("Shoot") then
						local params = baseProjectileParams
						params.FallingAccelModifier = -0.18
						params.BulletFlags = params.BulletFlags + ProjectileFlags.SINE_VELOCITY

						for i = -1, 1, 2 do
							local pos = getShootPos(i)
							for j = 0, 7 do
								fetus:FireProjectiles(pos, Vector.FromAngle(20 + j * 20):Resized(3), 0, params)
							end
							mod:ShootEffect(entity, 2, (pos + Vector(0, -20) - entity.Position) * 0.65)
						end

						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Sweeping line of shots ]]--
				elseif entity.State == NpcState.STATE_ATTACK4 then
					-- Start
					if entity.StateFrame == 0 then
						if sprite:IsFinished() then
							entity.StateFrame = 1
						end

					-- Loop
					elseif entity.StateFrame == 1 then
						mod:LoopingAnim(sprite, "ShootBothLoop")

						if entity.ProjectileDelay <= 0 then
							for i = -1, 1, 2 do
								local pos = getShootPos(i)
								local baseAngle = 90 - i * 45
								fetus:FireProjectiles(pos, Vector.FromAngle(baseAngle + i * entity.I1 * 15):Resized(5), 0, baseProjectileParams)
								mod:ShootEffect(entity, 2, (pos + Vector(0, -20) - entity.Position) * 0.65)
							end

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

							entity.I1 = entity.I1 + 1
							entity.ProjectileDelay = 5

						else
							entity.ProjectileDelay = entity.ProjectileDelay - 1
						end

						if entity.I1 >= 7 then
							entity.StateFrame = 2
							sprite:Play("ShootBothEnd", true)
						end

					-- Stop
					elseif entity.StateFrame == 2 then
						if sprite:IsFinished() then
							entity.State = NpcState.STATE_IDLE
						end
					end



				--[[ Spreads of 5 shots ]]--
				elseif entity.State == NpcState.STATE_ATTACK5 then
					if sprite:IsEventTriggered("Shoot") then
						local pos = getShootPos(entity.I1 % 2)
						fetus:FireProjectiles(pos, (target.Position - pos):Resized(5), 5, baseProjectileParams)

						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)
						mod:ShootEffect(entity, 2, (pos + Vector(0, -20) - entity.Position) * 0.65)

						entity.I1 = entity.I1 + 1
					end

					if sprite:IsFinished() then
						-- Do this 2 times
						if entity.I1 >= 2 then
							entity.State = NpcState.STATE_IDLE

						else
							-- Switch sides
							local side = "Left"
							if entity.I1 % 2 ~= 0 then
								side = "Right"
							end
							sprite:Play("Shoot" .. side, true)
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

		-- Reduced damage while hiding / during enrage animation
		elseif (target:ToNPC().State == NpcState.STATE_SUMMON2 or target:ToNPC().State == NpcState.STATE_SPECIAL or target:ToNPC().State == NpcState.STATE_SUMMON3)
		and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
			target:TakeDamage(damageAmount / 2, damageFlags + DamageFlag.DAMAGE_CLONES, damageSource, damageCountdownFrames)
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

		elseif projectile:HasProjectileFlags(ProjectileFlags.BURST) then
			projectile:Die()
			mod:PlaySound(nil, SoundEffect.SOUND_DEATH_BURST_SMALL)


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