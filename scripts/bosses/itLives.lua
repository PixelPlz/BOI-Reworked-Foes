local mod = BetterMonsters

local Settings = {
	-- Fetus
	FetusCooldown = 45,

	-- Guts
	GutsCooldown = 30,
}

IRFitLivesBosses = {
	{ -- 100% - 75%
		EntityType.ENTITY_OOB,
		EntityType.ENTITY_MONSTRO,
		EntityType.ENTITY_GEMINI,
	},
	{ -- 75% - 50%
		EntityType.ENTITY_COHORT,
		EntityType.ENTITY_FISTULA_BIG,
		EntityType.ENTITY_GURDY_JR,
	},
	{ -- 50% - 25%
		EntityType.ENTITY_ADULT_LEECH,
		EntityType.ENTITY_CHUB,
		EntityType.ENTITY_POLYCEPHALUS,
	},
}

IRFitLivesEnemies = {
	{ -- 100% - 75%
		EntityType.ENTITY_PARA_BITE,
		EntityType.ENTITY_WALKINGBOIL,
		EntityType.ENTITY_HOMUNCULUS,
	},
	{ -- 75% - 50%
		EntityType.ENTITY_SWINGER,
		EntityType.ENTITY_FISTULOID,
		EntityType.ENTITY_FACELESS,
	},
	{ -- 50% - 25%
		EntityType.ENTITY_LEECH,
		EntityType.ENTITY_TUMOR,
		EntityType.ENTITY_FLESH_MOBILE_HOST,
	},
}



function mod:itLivesInit(entity)
	-- Fetus
	if entity.Variant == 1 then
		local data = entity:GetData()

		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity.TargetPosition = entity.Position

		data.phase = 1
		data.attackCounter = 1
		data.spawnCounter = 1
		data.nextAttack = 1

		data.rotation = 1
		data.rotationDelay = 6

		mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_ISAAC)


	-- Guts
	elseif entity.Variant == 10 then
		-- Get the parent's variant
		entity.SubType = entity.SpawnerVariant

		-- It Lives' guts
		if entity.SubType == 1 then
			--entity:GetSprite():Load("gfx/078.010_it lives guts.anm2", true)
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
			--[[ Functions ]]--
			local function resetVariables()
				entity.ProjectileCooldown = Settings.FetusCooldown
				entity.I1 = 0
				entity.I2 = 0
				entity.StateFrame = 0
				entity.ProjectileDelay = 0

				sprite.Rotation = 0
				sprite.Offset = Vector.Zero
			end



			--[[ Always active ]]--
			local guts = nil
			if entity.Child then
				guts = entity.Child:ToNPC()
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
				data.spawnCounter = 1

				-- Enrage
				if data.phase == 4 then
					-- Come down first if retracted
					if entity.State == NpcState.STATE_JUMP or entity.State == NpcState.STATE_SUMMON2 then
						entity.State = NpcState.STATE_STOMP
						sprite:Play("HeartComedown", true)

					elseif entity.State ~= NpcState.STATE_STOMP and entity.State ~= NpcState.STATE_IDLE then
						entity.State = NpcState.STATE_IDLE
					end
				end
			end


			-- Heartbeat effect
			if entity:IsFrame(45 - (data.phase - 1) * 10, 0) then
				local sound = SoundEffect.SOUND_HEARTBEAT
				if data.phase == 3 then
					sound = SoundEffect.SOUND_HEARTBEAT_FASTER
				elseif data.phase == 4 then
					sound = SoundEffect.SOUND_HEARTBEAT_FASTEST
				end

				mod:PlaySound(nil, sound, 0.9)

				local beatPos = Vector(entity.Position.X, room:GetTopLeftPos().Y) - Vector(0, 160)
				local beatStrength = 0.013 - math.max(1, data.phase - 1) * 0.0015
				Game():MakeShockwave(beatPos, beatStrength, 0.025, 25)
			end


			-- Make other enemies not go near him
			local startPos = entity.Position
			if entity.State == NpcState.STATE_SUMMON2 then
				startPos = Vector(entity.Position.X, room:GetTopLeftPos().Y + 60)
			end

			for i = -1, 1 do
				for j = -1, 1 do
					local gridPos = startPos + Vector(i * 40, j * 40)
					local grid = room:GetGridIndex(gridPos)
					room:SetGridPath(grid, 900)
				end
			end



			--[[ Idle ]]--
			if entity.State == NpcState.STATE_IDLE then
				-- Homunculi
				if not data.homunculiSpawned and not data.wasDelirium then
					for i = -1, 1, 2 do
						local position = Vector(entity.Position.X + i * 160, room:GetTopLeftPos().Y + 80)
						Isaac.Spawn(EntityType.ENTITY_HOMUNCULUS, 0, 0, room:FindFreePickupSpawnPosition(position, 0, true, true), Vector.Zero, entity)
					end
					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)

					data.homunculiSpawned = true
					entity.ProjectileCooldown = Settings.FetusCooldown
				end


				mod:LoopingAnim(sprite, "Idle")

				-- Sway left and right
				if (data.rotation == 1 and sprite.Rotation < 1) or (data.rotation == -1 and sprite.Rotation > -1) then
					sprite.Rotation = sprite.Rotation + data.rotation * 0.04
					sprite.Offset = Vector(sprite.Rotation * -3, 0)
				else
					if data.rotationDelay <= 0 then
						data.rotation = data.rotation * -1
						data.rotationDelay = 6
					else
						data.rotationDelay = data.rotationDelay - 1
					end
				end


				-- Attack
				if entity.ProjectileCooldown <= 0 then
					resetVariables()

					-- Choose an attack, don't repeat it this cycle
					local function chooseAttack()
						attack = data.nextAttack

						if data.nextAttack >= 3 then
							data.nextAttack = 1
						else
							data.nextAttack = data.nextAttack + 1
						end

						if attack == 1 then
							entity.State = NpcState.STATE_ATTACK
							entity.StateFrame = mod:GetSign(target.Position.X > entity.Position.X)

						elseif attack == 2 then
							entity.State = NpcState.STATE_ATTACK2
							entity.StateFrame = mod:RandomSign()

						elseif attack == 3 then
							entity.State = NpcState.STATE_ATTACK3

						elseif attack == 4 then
							entity.State = NpcState.STATE_ATTACK
						end
						sprite:Play("HeartSummon", true)
					end


					-- Enraged
					if data.phase == 4 then
						-- Attack
						if data.attackCounter == 1 then
							chooseAttack()

						-- Attack
						elseif data.attackCounter == 2 then
							chooseAttack()

						-- Retract
						elseif data.attackCounter == 3 then
							entity.State = NpcState.STATE_JUMP
							sprite:Play("HeartRetracted", true)
						end


					-- Not enraged
					else
						-- Attack
						if data.attackCounter == 1 then
							chooseAttack()

						-- Summon enemies
						elseif data.attackCounter == 2 then
							guts.State = NpcState.STATE_SUMMON
							guts:GetSprite():Play("HeartSummon", true)

						-- Attack
						elseif data.attackCounter == 3 then
							chooseAttack()

						-- Summon harder enemies / retract
						elseif data.attackCounter == 4 then
							entity.State = NpcState.STATE_SUMMON
							sprite:Play("HeartSummon", true)
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
				if data.phase == 4 and not data.enraged then
					entity.State = NpcState.STATE_SPECIAL
					sprite:Play("HeartSummon", true)
					data.enraged = true

					resetVariables()
					data.attackCounter = 1

					-- Summon spikes to kill all enemies
					for i, enemy in pairs(Isaac.GetRoomEntities()) do
						if enemy:ToNPC() and enemy.Type ~= EntityType.ENTITY_MOMS_HEART then
							Isaac.Spawn(IRFentities.Type, IRFentities.GiantSpike, 0, enemy.Position, Vector.Zero, entity).Target = enemy
						end
					end
				end



			--[[ Overlapping lines of shots / Burst shot / Brimstone + lines of shots ]]--
			elseif entity.State == NpcState.STATE_ATTACK then
				-- Enraged
				if data.phase == 4 then
					mod:LoopingAnim(sprite, "Heartbeat3")

					if entity.ProjectileDelay <= 0 then
						for i = 0, 3 do
							-- Create the lasers
							if entity.I1 == 0 then
								local angle = 45 + i * 90
								local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position - Vector(0, 15), angle, 25, Vector.Zero, entity), entity}
								laser_ent_pair.laser:SetActiveRotation(10, entity.StateFrame * 180, entity.StateFrame * 1.5, -1)
							end

							entity:FireProjectiles(entity.Position, Vector.FromAngle(i * 90 + -entity.StateFrame * entity.I1 * 18):Resized(4.5), 0, baseProjectileParams)
						end

						entity.I1 = entity.I1 + 1
						entity.ProjectileDelay = 7

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I1 >= 16 then
						entity.State = NpcState.STATE_IDLE
					end


				-- First attack
				elseif data.attackCounter == 2 then
					mod:LoopingAnim(sprite, "Heartbeat3")

					if entity.ProjectileDelay <= 0 then
						for i = 0, 1 do
							local params = baseProjectileParams
							params.CircleAngle = 0 + (i * 0.8) + (mod:GetSign(i) * entity.I1 * 0.3)
							entity:FireProjectiles(entity.Position, Vector(6, 4), 9, params)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

						entity.I1 = entity.I1 + 1
						entity.ProjectileDelay = 4

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I1 >= 9 then
						entity.State = NpcState.STATE_IDLE
					end


				-- Second attack
				elseif data.attackCounter == 4 then
					if sprite:IsEventTriggered("Heartbeat") then
						local params = ProjectileParams()
						params.BulletFlags = (ProjectileFlags.ACID_RED | ProjectileFlags.RED_CREEP | ProjectileFlags.BURST8)
						params.Scale = 2.75
						entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(11), 0, params)
						mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end
				end



			--[[ Pulsating ring + stream of shots / Stomp ]]--
			elseif entity.State == NpcState.STATE_ATTACK2 then
				-- Enraged
				if data.phase == 4 then
					if sprite:IsEventTriggered("Heartbeat") then
						local offset = mod:Random(10, 100) * 0.01

						local params = baseProjectileParams
						params.CircleAngle = offset
						entity:FireProjectiles(entity.Position, Vector(9, 12), 9, params)

						params.CircleAngle = offset + 0.25
						params.FallingAccelModifier = -0.09
						params.BulletFlags = params.BulletFlags + ProjectileFlags.BOUNCE

						for i, projectile in pairs(mod:FireProjectiles(entity, entity.Position, Vector(7, 12), 9, params)) do
							mod:QuickTrail(projectile, 0.09, Color(1,0.25,0.25, 1), projectile.Scale * 1.75)
						end
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end


				-- First attack
				elseif data.attackCounter == 2 then
					mod:LoopingAnim(sprite, "Heartbeat2")

					if entity.ProjectileDelay <= 0 then
						local params = baseProjectileParams

						params.CircleAngle = 0 + entity.StateFrame * entity.I1 * 0.2
						entity:FireProjectiles(entity.Position, Vector(7, 4), 9, params)

						-- Pulsating shots
						if entity.I1 % 10 == 0 then
							params.Scale = 1.75
							params.BulletFlags = params.BulletFlags + ProjectileFlags.SINE_VELOCITY
							entity:FireProjectiles(entity.Position, Vector(3, 16), 9, params)
						end

						entity.I1 = entity.I1 + 1
						entity.ProjectileDelay = 4

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I1 >= 30 then
						entity.State = NpcState.STATE_IDLE
					end


				-- Second attack
				elseif data.attackCounter == 4 then
					-- Crackwaves
					if sprite:IsEventTriggered("Heartbeat") then
						for i = 0, 3 do
							local angle = 45 + i * 90
							Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACKWAVE, 2, entity.Position + Vector.FromAngle(angle):Resized(20), Vector.Zero, entity):ToEffect().Rotation = angle
						end
					end

					-- Falling projectiles
					if sprite:WasEventTriggered("Heartbeat") and entity.ProjectileDelay <= 0 then
						local pos = target.Position

						if entity.I1 == 0 then
							entity.V1 = (target.Position - entity.Position):Normalized()
						else
							pos = entity.Position + entity.V1:Rotated(entity.I1 * 120):Resized(mod:Random(60, 120))
						end
						pos = room:GetClampedPosition(pos, -10)

						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TARGET, 0, pos, Vector.Zero, entity):ToEffect().Timeout = 30

						local params = ProjectileParams()
						params.HeightModifier = -500
						params.FallingAccelModifier = 2.5
						params.BulletFlags = ProjectileFlags.EXPLODE
						params.Scale = 1.75
						mod:FireProjectiles(entity, pos, Vector.Zero, 0, params, Color.Default)

						entity.I1 = entity.I1 + 1
						entity.ProjectileDelay = 5

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I1 >= 3 then
						entity.State = NpcState.STATE_IDLE
					end
				end



			--[[ attack ]]--
			elseif entity.State == NpcState.STATE_ATTACK3 then
				-- Enraged
				if data.phase == 4 then
					mod:LoopingAnim(sprite, "Heartbeat3")

					if entity.ProjectileDelay <= 0 then
						local params = baseProjectileParams
						--params.BulletFlags = params.BulletFlags + ProjectileFlags.MEGA_WIGGLE
						params.BulletFlags = params.BulletFlags + ProjectileFlags.SINE_VELOCITY

						if entity.I1 % 2 == 0 then
							params.BulletFlags = params.BulletFlags + ProjectileFlags.CURVE_LEFT
						else
							params.BulletFlags = params.BulletFlags + ProjectileFlags.CURVE_RIGHT
						end
						params.CircleAngle = 0 + entity.I1 * 0.3
						entity:FireProjectiles(entity.Position, Vector(4, 8), 9, params)

						entity.I1 = entity.I1 + 1
						entity.ProjectileDelay = 10

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I1 >= 10 then
						entity.State = NpcState.STATE_IDLE
					end


				-- First attack
				elseif data.attackCounter == 2 then
					mod:LoopingAnim(sprite, "Heartbeat2")

					if entity.ProjectileDelay <= 0 then
					--if sprite:IsEventTriggered("Heartbeat") then
						local params = baseProjectileParams

						params.CircleAngle = 0 + entity.I1 * 0.3
						entity:FireProjectiles(entity.Position, Vector(6, 5), 9, params)

						params.CircleAngle = 0 - entity.I1 * 0.3
						entity:FireProjectiles(entity.Position, Vector(3, 5), 9, params)

						entity.I1 = entity.I1 + 1
						entity.ProjectileDelay = 8

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I1 >= 15 then
						entity.State = NpcState.STATE_IDLE
					end


				-- Second attack
				elseif data.attackCounter == 4 then
					mod:LoopingAnim(sprite, "Heartbeat2")

					if entity.ProjectileDelay <= 0 then
						local params = ProjectileParams()
						params.Scale = 2
						params.BulletFlags = (ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.CHANGE_VELOCITY_AFTER_TIMEOUT)
						params.ChangeFlags = ProjectileFlags.BURST
						params.ChangeVelocity = 9
						params.Acceleration = 1.1
						params.FallingAccelModifier = -0.175

						params.ChangeTimeout = 30 + entity.I1 * 2
						mod:FireProjectiles(entity, entity.Position, mod:RandomVector(mod:Random(8, 11)), 0, params, Color.Default)

						entity.I1 = entity.I1 + 1
						entity.ProjectileDelay = 1

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I1 >= 8 then
						entity.State = NpcState.STATE_IDLE
					end
				end



			--[[ Summon ]]--
			elseif entity.State == NpcState.STATE_SUMMON then
				if sprite:IsEventTriggered("Heartbeat") then
					local spawnGroup = IRFitLivesBosses[data.phase]
					local spawnType = spawnGroup[data.spawnCounter]

					-- For Chub
					if spawnType == EntityType.ENTITY_CHUB then
						for i = -1, 1 do
							Isaac.Spawn(spawnType, 0, 0, entity.Position + Vector(i * 30, 30), Vector.Zero, entity)
						end
					else
						Isaac.Spawn(spawnType, 0, 0, entity.Position + Vector(0, 30), Vector.Zero, entity)
					end

					-- Always follow the same order
					if data.spawnCounter >= 3 then
						data.spawnCounter = 1
					else
						data.spawnCounter = data.spawnCounter + 1
					end

					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
					mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_EVILLAUGH)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("HeartRetracted", true)
				end



			--[[ Retract ]]--
			elseif entity.State == NpcState.STATE_JUMP then
				if sprite:GetFrame() == 5 then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					mod:PlaySound(nil, SoundEffect.SOUND_HEARTIN)
					entity:RemoveStatusEffects()
				end

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
				if sprite:GetFrame() == 5 then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
					mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT)
					mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_ISAAC)
					Game():ShakeScreen(8)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end



			--[[ Retracted ]]--
			elseif entity.State == NpcState.STATE_SUMMON2 then
				mod:LoopingAnim(sprite, "HeartHidingHeartbeat")

				-- Come down if all enemies are dead
				if spawnedEnemyCount <= 0 then
					-- Delay before coming down
					if entity.StateFrame <= 0 then
						entity.State = NpcState.STATE_STOMP
						sprite:Play("HeartComedown", true)

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
				if sprite:IsEventTriggered("Heartbeat") then
					mod:PlaySound(entity, SoundEffect.SOUND_MULTI_SCREAM)
					entity:SetColor(Color(1,1,1, 1, 0.5,0,0), -1, 1, false, true)
					Game():MakeShockwave(entity.Position, 0.02, 0.025, 15)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("HeartRetracted", true)
				end
			
			
			
			--[[ Blood cell attacks ]]--
			elseif entity.State == NpcState.STATE_SUMMON3 then
				mod:LoopingAnim(sprite, "HeartHidingHeartbeat")

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
						local popMax = 70

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
						params.FallingAccelModifier = -0.18
						params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.WIGGLE)

						local burstChoice = mod:Random(-1, 1)


						for i = iMin, iMax do
							local evenOrNot = entity.I1 % 2
							local pos = basePos + Vector.FromAngle(direction):Rotated(90):Resized(i * distance + evenOrNot * 40)

							local shot = mod:FireProjectiles(entity, pos, Vector.FromAngle(direction):Resized(6), 0, params)
							shot:GetSprite():Load("gfx/blood cell projectile.anm2", true)

							-- Bursting cell
							if evenOrNot == 0 and i == burstChoice then
								shot:GetData().splitTimer = mod:Random(popMin, popMax)
								shot:GetSprite():Play("IdleBurst", true)
							else
								shot:GetSprite():Play("Idle", true)
							end
						end

						entity.ProjectileDelay = 22
						entity.I1 = entity.I1 + 1

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end


				-- Come down after all the lines have spawned
				else
					-- Delay before coming down
					if entity.StateFrame <= 0 then
						entity.State = NpcState.STATE_STOMP
						sprite:Play("HeartComedown", true)

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
				--entity:Kill()


			else
				--[[ Functions ]]--
				-- Get shoot positions
				local function getShootPos(side)
					local position = Vector(entity.Position.X, room:GetTopLeftPos().Y + 15)
					local sign = mod:GetSign(side > 0)
					return position + sign * Vector(120, 0)
				end



				--[[ Always active ]]--
				local fetus = entity.Parent:ToNPC()

				-- Make enemies not go near the holes
				for side = -1, 1, 2 do
					for i = -1, 1 do
						for j = 0, 1 do
							local startPos = getShootPos(side)
							local gridPos = startPos + Vector(i * 40, j * 40)
							local grid = room:GetGridIndex(gridPos)
							room:SetGridPath(grid, 900)
						end
					end
				end



				--[[ Idle ]]--
				if entity.State == NpcState.STATE_IDLE then
					mod:LoopingAnim(sprite, "Heartbeat1")

					if fetus.State == NpcState.STATE_SUMMON2 then
						if entity.ProjectileCooldown <= 0 then
							entity.ProjectileCooldown = Settings.GutsCooldown
							entity.I1 = 0
							entity.I2 = 0
							entity.StateFrame = 0
							entity.ProjectileDelay = 0

							local attack = mod:Random(1, 5)
							--attack = 5

							if attack == 1 then
								entity.State = NpcState.STATE_ATTACK

							elseif attack == 2 then
								entity.State = NpcState.STATE_ATTACK2

							elseif attack == 3 then
								entity.State = NpcState.STATE_ATTACK3

							elseif attack == 4 then
								entity.State = NpcState.STATE_ATTACK4

							elseif attack == 5 then
								entity.State = NpcState.STATE_ATTACK5
							end
							sprite:Play("HeartSummon", true)

						else
							entity.ProjectileCooldown = entity.ProjectileCooldown - 1
						end
					end



				--[[ Summon ]]--
				elseif entity.State == NpcState.STATE_SUMMON then
					if sprite:GetFrame() == 5 then
						local spawnGroup = IRFitLivesEnemies[fetus:GetData().phase]
						local spawnType = mod:RandomIndex(spawnGroup)

						for i = -1, 1, 2 do
							Isaac.Spawn(spawnType, 0, 0, getShootPos(i), Vector.Zero, fetus)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Attack ]]--
				elseif entity.State == NpcState.STATE_ATTACK then
					if sprite:GetFrame() == 5 then
						if entity.I1 < 5 then
							sprite:SetFrame(0)
						else
							entity.I1 = 0
						end

						for i = -1, 1, 2 do
							local pos = getShootPos(i)
							fetus:FireProjectiles(pos, (target.Position - pos):Resized(6), 0, baseProjectileParams)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

						entity.I1 = entity.I1 + 1
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Attack ]]--
				elseif entity.State == NpcState.STATE_ATTACK2 then
					if sprite:GetFrame() == 5 then
						local params = baseProjectileParams
						for i = -1, 1, 2 do
							local pos = getShootPos(i)
							params.CircleAngle = 0 + i * entity.I1 * 0.3
							fetus:FireProjectiles(pos, Vector(4, 4), 9, params)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

						entity.I1 = entity.I1 + 1

					elseif sprite:GetFrame() == 10 then
						if entity.I1 < 10 then
							sprite:SetFrame(0)
						else
							entity.I1 = 0
						end
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Attack ]]--
				elseif entity.State == NpcState.STATE_ATTACK3 then
					if sprite:GetFrame() == 5 then
						local params = baseProjectileParams
						params.FallingAccelModifier = -0.18
						params.BulletFlags = params.BulletFlags + ProjectileFlags.SINE_VELOCITY

						for i = -1, 1, 2 do
							for j = 0, 7 do
								fetus:FireProjectiles(getShootPos(i), Vector.FromAngle(20 + j * 20):Resized(3), 0, params)
							end
						end
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Attack ]]--
				elseif entity.State == NpcState.STATE_ATTACK4 then
					if sprite:GetFrame() == 5 then
						local pos = getShootPos(entity.I1)
						fetus:FireProjectiles(pos, (target.Position - pos):Resized(5), 5, baseProjectileParams)
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

						entity.I1 = entity.I1 + 1

					elseif sprite:GetFrame() == 20 then
						if entity.I1 < 2 then
							sprite:SetFrame(0)
						else
							entity.I1 = 0
						end
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Attack ]]--
				elseif entity.State == NpcState.STATE_ATTACK5 then
					if sprite:GetFrame() == 5 then
						local params = baseProjectileParams
						for i = -1, 1, 2 do
							local pos = getShootPos(i)
							params.CircleAngle = 0 + i * entity.I1 * 0.3
							fetus:FireProjectiles(pos, Vector(4, 4), 9, params)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

						entity.I1 = entity.I1 + 1

					elseif sprite:GetFrame() == 10 then
						if entity.I1 < 10 then
							sprite:SetFrame(0)
						else
							entity.I1 = 0
						end
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end
				end
			end
		end


		if entity.FrameCount > 1 and (entity.Variant == 10 or not entity:HasMortalDamage()) then
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



-- Burst projectiles
function mod:itLivesProjectileUpdate(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_MOMS_HEART and projectile.SpawnerVariant == 1 then
		local sprite = projectile:GetSprite()
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