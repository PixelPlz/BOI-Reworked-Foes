local mod = BetterMonsters

local Settings = {
	-- Fetus
	FetusCooldown = 60,
	FetusSpawnCooldown = 300,

	-- Guts
	GutsCooldown = 60,
	GutsSpawnCooldown = 180,
}

IRFitLivesBosses = {
	{ -- 75% - 50%
		EntityType.ENTITY_FISTULA_BIG,
		EntityType.ENTITY_GURDY_JR,
	},
	{ -- 50% - 25%
		EntityType.ENTITY_CHUB,
		EntityType.ENTITY_POLYCEPHALUS
	},
}

IRFitLivesEnemies = {
	{ -- 100% - 75%
		EntityType.ENTITY_GLOBIN,
		EntityType.ENTITY_WALKINGBOIL,
		EntityType.ENTITY_HOMUNCULUS,
	},
	{ -- 75% - 50%
		EntityType.ENTITY_PARA_BITE,
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
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity.TargetPosition = entity.Position

		entity.ProjectileCooldown = Settings.FetusCooldown
		entity:GetData().spawnCooldown = 0

		mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_ISAAC)


	-- Guts
	elseif entity.Variant == 10 then
		-- Get the parent's variant
		entity.SubType = entity.SpawnerVariant

		-- It Lives' guts
		if entity.SubType == 1 then
			--entity:GetSprite():Load("gfx/078.010_it lives guts.anm2", true)

			entity.ProjectileCooldown = Settings.GutsCooldown
			entity:GetData().spawnCooldown = Settings.GutsSpawnCooldown / 2

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
			-- Enrage
			local function enrage()
				-- angy
			end



			--[[ Always active ]]--
			-- Always stay in the spawn position
			entity.Velocity = Vector.Zero
			entity.Position = entity.TargetPosition

			if entity:HasEntityFlags(EntityFlag.FLAG_KNOCKED_BACK) then
				entity:ClearEntityFlags(EntityFlag.FLAG_KNOCKED_BACK)
			end


			-- Transition to next phase
			local quarterHp = (entity.MaxHitPoints / 4)

			if entity.HitPoints <= entity.MaxHitPoints - (quarterHp * entity.I1) then
				entity.I1 = entity.I1 + 1
				entity.I2 = 0

				-- Enrage
				if entity.I1 == 4 then
					entity.State = NpcState.STATE_SPECIAL
					sprite:Play("HeartSummon", true)
					mod:PlaySound(entity, SoundEffect.SOUND_MULTI_SCREAM)
					entity:SetColor(Color(1,1,1, 1, 0.5,0,0), -1, 1, false, true)
					Game():MakeShockwave(entity.Position, 0.02, 0.025, 15)

					-- placeholder
					for i, enemy in pairs(Isaac.GetRoomEntities()) do
						if enemy:ToNPC() and enemy.Type ~= EntityType.ENTITY_MOMS_HEART then
							local spike = Isaac.Spawn(IRFentities.Type, IRFentities.GiantSpike, 0, enemy.Position, Vector.Zero, entity):ToNPC()
							spike.Target = enemy
							spike.I1 = 15
							spike.I2 = 15
						end
					end

				-- Summon a boss
				elseif entity.I1 >= 2 then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("HeartSummon", true)
					entity.Child:ToNPC().State = NpcState.STATE_SUMMON
					entity.Child:GetSprite():Play("HeartSummon", true)
				end
			end


			-- Make other enemies not go near him
			local startPos = entity.Position
			if entity.State == NpcState.STATE_MOVE then
				startPos = Vector(entity.Position.X, room:GetTopLeftPos().Y + 60)
			end

			for i = -1, 1 do
				for j = -1, 1 do
					local gridPos = startPos + Vector(i * 40, j * 40)
					local grid = room:GetGridIndex(gridPos)
					room:SetGridPath(grid, 900)
				end
			end


			-- Heartbeat effect
			if entity:IsFrame(45 - (entity.I1 - 1) * 10, 0) then
				local beatPos = Vector(entity.Position.X, room:GetTopLeftPos().Y) - Vector(0, 160)
				Game():MakeShockwave(beatPos, 0.02, 0.025, 15)
				
				local sound = SoundEffect.SOUND_HEARTBEAT
				if entity.I1 == 4 then
					sound = SoundEffect.SOUND_HEARTBEAT_FASTER
				end
				mod:PlaySound(nil, sound, 0.8)
			end



			--[[ Idle ]]--
			if entity.State == NpcState.STATE_IDLE then
				-- Homunculi
				if not data.homunculiSpawned then
					for i = -1, 1, 2 do
						local position = Vector(entity.Position.X + i * 160, room:GetTopLeftPos().Y + 80)
						Isaac.Spawn(EntityType.ENTITY_HOMUNCULUS, 0, 0, room:FindFreePickupSpawnPosition(position, 0, true, true), Vector.Zero, entity)
					end

					data.homunculiSpawned = true
					entity.ProjectileCooldown = Settings.FetusCooldown / 2
					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
				end


				mod:LoopingAnim(sprite, "Idle")

				-- Boss spawn cooldown
				if data.spawnCooldown > 0 then
					data.spawnCooldown = data.spawnCooldown - 1
				end

				-- Attack
				if entity.ProjectileCooldown <= 0 then
					entity.ProjectileCooldown = Settings.FetusCooldown
					entity.I2 = 0
					entity.ProjectileDelay = 0

					local maxAttack = 4
					if (entity.I1 == 2 or entity.I1 == 3) and data.spawnCooldown <= 0 and not data.wasDelirium then
						--maxAttack = 5
					end
					local attack = mod:Random(1, maxAttack)
					if entity.I1 > 1 then
						--attack = 5
					end


					-- Burst shot
					if attack == 1 then
						entity.State = NpcState.STATE_ATTACK
						sprite:Play("HeartSummon", true)

					-- Overlapping lines of shots
					elseif attack == 2 then
						entity.State = NpcState.STATE_ATTACK2
						entity.ProjectileDelay = 0
						mod:PlaySound(entity, SoundEffect.SOUND_MULTI_SCREAM)
						Game():MakeShockwave(entity.Position - Vector(0, 60), 0.025, 0.025, 10)

						entity.StateFrame = mod:GetSign(target.Position.X > entity.Position.X)

					-- Wiggle shots
					elseif attack == 3 then
						if entity.I1 == 4 then
							entity.State = NpcState.STATE_JUMP
							sprite:Play("HeartRetracted", true)
							mod:PlaySound(nil, SoundEffect.SOUND_HEARTIN)
						else
							entity.State = NpcState.STATE_ATTACK3
						end

					-- Slam falling shots
					elseif attack == 4 then
						entity.State = NpcState.STATE_ATTACK4
						--sprite:Play("HeartSummon", true)
						mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_HURT)
						entity.StateFrame = mod:RandomSign()

					-- Summon a boss
					elseif attack == 5 then
						entity.State = NpcState.STATE_SUMMON
						sprite:Play("HeartSummon", true)
						mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_EVILLAUGH)
						data.spawnCooldown = Settings.FetusSpawnCooldown
					end

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end



			--[[ Burst shot ]]--
			elseif entity.State == NpcState.STATE_ATTACK then
				-- Movement predicting lines
				if entity.I1 == 4 then
					mod:LoopingAnim(sprite, "Heartbeat3")

					if entity.ProjectileDelay <= 0 then
					--if sprite:IsEventTriggered("Heartbeat") then
						--[[
						for i = 0, 4 do
							local targetPos = target.Position
							if entity.I2 >= 10 then
								targetPos = target.Position - target.Velocity:Resized(40)
								
								if entity.I2 % 10 == 0 then
									entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Rotated(i * 72):Resized(8), 0, baseProjectileParams)
								end
							end
							entity:FireProjectiles(entity.Position, (targetPos - entity.Position):Rotated(36 + i * 72):Resized(7), 0, baseProjectileParams)
						end
						]]--
						
						local params = baseProjectileParams
						--params.BulletFlags = params.BulletFlags + ProjectileFlags.MEGA_WIGGLE
						params.BulletFlags = params.BulletFlags + ProjectileFlags.SINE_VELOCITY

						if entity.I2 % 2 == 0 then
							params.BulletFlags = params.BulletFlags + ProjectileFlags.CURVE_LEFT
						else
							params.BulletFlags = params.BulletFlags + ProjectileFlags.CURVE_RIGHT
						end
						params.CircleAngle = 0 + entity.I2 * 0.3
						entity:FireProjectiles(entity.Position, Vector(4.5, 6), 9, params)

						entity.I2 = entity.I2 + 1
						entity.ProjectileDelay = 10
						

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I2 >= 10 then
						entity.State = NpcState.STATE_IDLE
					end


				-- Burst shot
				else
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



			--[[ Overlapping lines of shots / + Brimstones ]]--
			elseif entity.State == NpcState.STATE_ATTACK2 then
				-- Overlapping lines of shots + Brimstones
				if entity.I1 == 4 then
					mod:LoopingAnim(sprite, "Heartbeat3")

					if entity.ProjectileDelay <= 0 then
					--if sprite:IsEventTriggered("Heartbeat") then
						for i = 0, 3 do
							if entity.I2 == 0 then
								local angle = 45 + i * 90
								local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position - Vector(0, 15), angle, 25, Vector.Zero, entity), entity}
								laser_ent_pair.laser:SetActiveRotation(10, entity.StateFrame * 180, entity.StateFrame * 1.5, -1)
							end

							entity:FireProjectiles(entity.Position, Vector.FromAngle(i * 90 + -entity.StateFrame * entity.I2 * 18):Resized(4.5), 0, baseProjectileParams)
						end

						entity.I2 = entity.I2 + 1
						entity.ProjectileDelay = 7

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I2 >= 16 then
					--if not data.brim then
						entity.State = NpcState.STATE_IDLE
					end


				-- Overlapping lines of shots
				else
					mod:LoopingAnim(sprite, "Heartbeat3")

					--if entity.ProjectileDelay <= 0 then
					if sprite:IsEventTriggered("Heartbeat") then
						for i = 0, 1 do
							local params = baseProjectileParams
							params.CircleAngle = 0 + (i * 0.8) + (mod:GetSign(i) * entity.I2 * 0.3)
							entity:FireProjectiles(entity.Position, Vector(6, 4), 9, params)
						end
						entity.I2 = entity.I2 + 1
						--entity.ProjectileDelay = 9
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

					--else
						--entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I2 >= 9 then
						entity.State = NpcState.STATE_IDLE
					end
				end



			--[[ Wiggle shots ]]--
			elseif entity.State == NpcState.STATE_ATTACK3 then
				-- Opposite rotation shots
				if entity.I1 == 4 then
					mod:LoopingAnim(sprite, "Heartbeat2")

					--if entity.ProjectileDelay <= 0 then
					if sprite:IsEventTriggered("Heartbeat") then
						local params = baseProjectileParams

						params.CircleAngle = 0 + entity.I2 * 0.3
						entity:FireProjectiles(entity.Position, Vector(6, 4), 9, params)

						params.CircleAngle = 0 - entity.I2 * 0.3
						entity:FireProjectiles(entity.Position, Vector(3, 4), 9, params)

						entity.I2 = entity.I2 + 1
						--entity.ProjectileDelay = 2

					--else
						--entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I2 >= 15 then
						entity.State = NpcState.STATE_IDLE
					end


				-- Wiggle shots
				else
					mod:LoopingAnim(sprite, "Heartbeat3")

					--if entity.ProjectileDelay <= 0 then
					if sprite:IsEventTriggered("Heartbeat") then
						local params = baseProjectileParams
						params.BulletFlags = params.BulletFlags + ProjectileFlags.MEGA_WIGGLE
						params.CircleAngle = 0 + entity.I2 * 0.3
						if entity.I2 % 2 == 0 then
							params.WiggleFrameOffset = 10
						end
						entity:FireProjectiles(entity.Position, Vector(8, 6), 9, params)

						entity.I2 = entity.I2 + 1
						--entity.ProjectileDelay = 4
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

					--else
						--entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I2 >= 6 then
						entity.State = NpcState.STATE_IDLE
					end
				end



			--[[ Slam falling shots ]]--
			elseif entity.State == NpcState.STATE_ATTACK4 then
				-- Pulsating stream
				if entity.I1 == 4 then
					mod:LoopingAnim(sprite, "Heartbeat2")

					if entity.ProjectileDelay <= 0 then
					--if sprite:IsEventTriggered("Heartbeat") then
						local params = baseProjectileParams
						
						params.CircleAngle = 0 + entity.StateFrame * entity.I2 * 0.2
						entity:FireProjectiles(entity.Position, Vector(7, 4), 9, baseProjectileParams)
						
						if entity.I2 % 10 == 0 then
							--params.CircleAngle = 0 + (entity.I2 % 20) * 0.55
							params.Scale = 1.75
							params.BulletFlags = params.BulletFlags + ProjectileFlags.SINE_VELOCITY
							entity:FireProjectiles(entity.Position, Vector(3, 16), 9, baseProjectileParams)
						end

						entity.I2 = entity.I2 + 1
						entity.ProjectileDelay = 4
						

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I2 >= 30 then
						entity.State = NpcState.STATE_IDLE
					end
				
				-- Slam falling shots
				else
					mod:LoopingAnim(sprite, "Heartbeat3")

					--if entity.ProjectileDelay <= 0 then
					if sprite:IsEventTriggered("Heartbeat") then
						local pos = target.Position
						if entity.I2 == 2 then
							pos = entity.Position + mod:RandomVector(mod:Random(80, 160))
						elseif entity.I2 == 1 then
							pos = target.Position + mod:RandomVector(mod:Random(40, 120))
						end
						pos = room:GetClampedPosition(pos, -10)

						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TARGET, 0, pos, Vector.Zero, entity):ToEffect().Timeout = 30

						local params = ProjectileParams()
						params.HeightModifier = -500
						params.FallingAccelModifier = 2.5
						params.BulletFlags = (ProjectileFlags.EXPLODE | ProjectileFlags.ACID_GREEN) -- The red version just doesn't work???
						params.Scale = 1.75
						mod:FireProjectiles(entity, pos, Vector.Zero, 0, params, Color.Default)

						entity.I2 = entity.I2 + 1

					--else
						--entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I2 >= 3 then
						entity.State = NpcState.STATE_IDLE
					end
				end



			--[[ Summon a boss ]]--
			elseif entity.State == NpcState.STATE_SUMMON then
				if sprite:IsEventTriggered("Heartbeat") then
					local spawnGroup = IRFitLivesBosses[entity.I1 - 1]
					local spawnType = mod:RandomIndex(spawnGroup)

					-- For Chub
					if spawnType == EntityType.ENTITY_CHUB then
						for i = -1, 1 do
							Isaac.Spawn(spawnType, 0, 0, entity.Position + Vector(i * 30, 20), Vector.Zero, entity)
						end
					else
						Isaac.Spawn(spawnType, 0, 0, entity.Position + Vector(0, 20), Vector.Zero, entity)
					end

					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
					mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_EVILLAUGH)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("HeartRetracted", true)
					mod:PlaySound(nil, SoundEffect.SOUND_HEARTIN)
				end


			-- Hide
			elseif entity.State == NpcState.STATE_JUMP then
				if sprite:IsFinished() then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

					if entity.I1 == 4 and mod:Random(1) == 1 then
						entity.State = NpcState.STATE_ATTACK5
						entity.StateFrame = mod:Random(3)
					else
						entity.State = NpcState.STATE_MOVE
						entity.StateFrame = mod:Random(2)
					end
				end


			-- Retracted
			elseif entity.State == NpcState.STATE_MOVE then
				mod:LoopingAnim(sprite, "HeartHidingHeartbeat")

				if sprite:IsEventTriggered("Heartbeat") then
				--if entity.ProjectileDelay <= 0 then
					if entity.I1 == 4 then
						local iMin = -1
						local iMax = 1
						local distance = 100
						local basePos = Vector(room:GetTopLeftPos().X - 140, room:GetCenterPos().Y - 20)
						local direction = 0
						local popMin = 10
						local popMax = 80

						--entity.StateFrame = 2
						if entity.StateFrame == 1 then
							basePos = Vector(room:GetBottomRightPos().X + 140, room:GetCenterPos().Y + 20)
							direction = 180

						elseif entity.StateFrame == 2 then
							iMin = -2
							iMax = 2
							distance = 110
							basePos = Vector(room:GetCenterPos().X + 20, room:GetTopLeftPos().Y - 80)
							direction = 90
							popMin = 0
							popMax = 30
						end
						local burstChoice = mod:Random(iMin, iMax)


						local params = ProjectileParams()
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.18
						params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.WIGGLE)

						for i = iMin, iMax do
							local evenOrNot = entity.I2 % 2
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


					else
						local pos = Vector(entity.Position.X, room:GetTopLeftPos().Y + 20)
						local params = baseProjectileParams

						params.CircleAngle = 0 + entity.I2 * 0.3
						entity:FireProjectiles(pos, Vector(6, 4), 9, params)

						params.CircleAngle = 0 - entity.I2 * 0.3
						entity:FireProjectiles(pos, Vector(3, 4), 9, params)
					end


					entity.I2 = entity.I2 + 1
				
				--else
					--entity.ProjectileDelay = entity.ProjectileDelay - 1
				end

				if (entity.I1 == 4 and entity.I2 >= 16) or (entity.I1 ~= 4 and spawnedEnemyCount <= 0) then
					entity.State = NpcState.STATE_STOMP
					sprite:Play("HeartComedown", true)
					mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT)
				end

			-- Alt
			elseif entity.State == NpcState.STATE_ATTACK5 then
				mod:LoopingAnim(sprite, "HeartHidingHeartbeat")

				--if sprite:IsEventTriggered("Heartbeat") then
				if entity.ProjectileDelay <= 0 then
					local horiBasePos = Vector(room:GetTopLeftPos().X - 140, room:GetCenterPos().Y + 5)
					local horiDirection = 0
					local horiDistance = 60

					local vertBasePos = Vector(room:GetCenterPos().X, room:GetTopLeftPos().Y - 80)
					local vertDirection = 90
					local vertDistance = 80

					local params = ProjectileParams()
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.18
					params.BulletFlags = ProjectileFlags.NO_WALL_COLLIDE

					local randone = mod:Random(2)
					for i = -2, 2 do
						if i ~= randone then
							local pos = horiBasePos + Vector.FromAngle(horiDirection):Rotated(90):Resized(i * horiDistance)

							local shot = mod:FireProjectiles(entity, pos, Vector.FromAngle(horiDirection):Resized(4), 0, params)
							shot:GetSprite():Load("gfx/blood cell projectile.anm2", true)
							shot:GetSprite():Play("Idle", true)
						end
					end

					for i = -3, 3 do
						local pos = vertBasePos + Vector.FromAngle(vertDirection):Rotated(90):Resized(i * vertDistance)

						local shot = mod:FireProjectiles(entity, pos, Vector.FromAngle(vertDirection):Resized(4), 0, params)
						shot:GetSprite():Load("gfx/blood cell projectile.anm2", true)
						shot:GetSprite():Play("Idle", true)
					end

					local fetusPos = Vector(entity.Position.X, room:GetTopLeftPos().Y + 20)
					mod:FireProjectiles(entity, fetusPos, (target.Position - fetusPos):Resized(9), 0, baseProjectileParams, Color.Default)
					entity.ProjectileDelay = 35
					entity.I2 = entity.I2 + 1
				
				else
					entity.ProjectileDelay = entity.ProjectileDelay - 1
				end

				if entity.I2 >= 12 then
					entity.State = NpcState.STATE_STOMP
					sprite:Play("HeartComedown", true)
					mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT)
				end


			-- Come down
			elseif entity.State == NpcState.STATE_STOMP then
				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
					if entity.I1 == 4 then
						entity.ProjectileCooldown = Settings.FetusCooldown * 1.5
					end
				end



			--[[ Enrage ]]--
			elseif entity.State == NpcState.STATE_SPECIAL then
				if sprite:IsFinished() then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("HeartRetracted", true)
					mod:PlaySound(nil, SoundEffect.SOUND_HEARTIN)
				end
			end





		--[[ Guts ]]--
		elseif entity.Variant == 10 then
			-- Die without a parent
			if not entity.Parent or entity.Parent:IsDead() then
				--entity.State = NpcState.STATE_DEATH
				--sprite:Play("Death", true)
				entity:Kill()


			else
				--[[ Functions ]]--
				-- Get shoot positions
				local function getShootPos(side)
					local position = Vector(entity.Position.X, room:GetTopLeftPos().Y + 15)
					local sign = mod:GetSign(side > 0)
					return position + sign * Vector(120, 0)
				end



				--[[ Always active ]]--
				--entity.Parent.Child = entity
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

					-- Enemy spawn cooldown
					if data.spawnCooldown > 0 then
						data.spawnCooldown = data.spawnCooldown - 1
					end

					-- Attack
					if entity.ProjectileCooldown <= 0 and fetus.I1 ~= 4 then
						entity.ProjectileCooldown = Settings.GutsCooldown
						entity.I2 = 0

						local maxAttack = 4
						if fetus.I1 <= 3 and spawnedEnemyCount <= 3 and data.spawnCooldown <= 0 then
							maxAttack = 6
						end
						local attack = mod:Random(1, maxAttack)


						-- Stream of shots at the player
						if attack == 1 then
							entity.State = NpcState.STATE_ATTACK
							sprite:Play("HeartSummon", true)
							entity.I1 = mod:Random(4)

						-- Spread of 6 shots downwards
						elseif attack == 2 then
							entity.State = NpcState.STATE_ATTACK2
							sprite:Play("HeartSummon", true)

						-- Spread of 5 shots at the player from a random side
						elseif attack == 3 then
							entity.State = NpcState.STATE_ATTACK3
							sprite:Play("HeartSummon", true)

						-- Curving Brimstones
						elseif attack == 4 then
							entity.State = NpcState.STATE_ATTACK4
							sprite:Play("HeartSummon", true)

						-- Summon
						elseif attack >= 5 then -- Twice as likely to be chosen
							entity.State = NpcState.STATE_SUMMON
							sprite:Play("HeartSummon", true)
							data.spawnCooldown = Settings.GutsSpawnCooldown
						end

					-- Don't attack during the boss summoning attack
					elseif fetus.State ~= NpcState.STATE_SUMMON and fetus.State ~= NpcState.STATE_JUMP and fetus.State ~= NpcState.STATE_MOVE and fetus.State ~= NpcState.STATE_STOMP then
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end



				--[[ Stream of shots at the player ]]--
				elseif entity.State == NpcState.STATE_ATTACK then
					if sprite:GetFrame() == 5 then


						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

						if entity.I2 < 5 then
							sprite:SetFrame(0)
						else
							entity.I2 = 0
						end

						for i = -1, 1, 2 do
							local pos = getShootPos(i)
							fetus:FireProjectiles(pos, (target.Position - pos):Resized(6.5), 0, baseProjectileParams)
						end

						entity.I2 = entity.I2 + 1
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Spread of 6 shots downwards ]]--
				elseif entity.State == NpcState.STATE_ATTACK2 then
					if sprite:GetFrame() == 5 then


						mod:PlaySound(nil, SoundEffect.SOUND_MEATHEADSHOOT)

						for i = -1, 1, 2 do
							for j = 0, 5 do
								fetus:FireProjectiles(getShootPos(i), Vector.FromAngle(15 + j * 30):Resized(5.5), 0, baseProjectileParams)
							end
						end
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Spread of 5 shots at the player from a random side ]]--
				elseif entity.State == NpcState.STATE_ATTACK3 then
					if sprite:GetFrame() == 5 then


						mod:PlaySound(nil, SoundEffect.SOUND_MEATHEADSHOOT)

						local pos = getShootPos(mod:Random(1))
						fetus:FireProjectiles(pos, (target.Position - pos):Resized(6), 5, baseProjectileParams)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Curving Brimstones ]]--
				elseif entity.State == NpcState.STATE_ATTACK4 then
					if sprite:GetFrame() == 5 then
						for i = -1, 1, 2 do
							local angle = 90 - i * 8
							local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, getShootPos(i) - Vector(0, 15), angle, 25, Vector.Zero, entity), entity}
							laser_ent_pair.laser:SetActiveRotation(0, i * 16, i, -1)
						end
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Summon enemies ]]--
				elseif entity.State == NpcState.STATE_SUMMON then
					if sprite:GetFrame() == 5 then
						local spawnGroup = IRFitLivesEnemies[fetus.I1]
						local spawnType = mod:RandomIndex(spawnGroup)

						for i = -1, 1, 2 do
							Isaac.Spawn(spawnType, 0, 0, getShootPos(i), Vector.Zero, fetus)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
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

function mod:itLivesProjectileUpdate(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_MOMS_HEART and projectile.SpawnerVariant == 1 then
		local sprite = projectile:GetSprite()
		local data = projectile:GetData()

		-- Burst projectile fix
		if projectile:HasProjectileFlags(ProjectileFlags.ACID_RED | ProjectileFlags.RED_CREEP) and not projectile:HasProjectileFlags(ProjectileFlags.BURST8) then
			projectile:ClearProjectileFlags(ProjectileFlags.ACID_RED | ProjectileFlags.RED_CREEP)


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

-- Creep fix
function mod:itLivesCreepUpdate(effect)
	if effect.SpawnerEntity and effect.SpawnerEntity.SpawnerType == EntityType.ENTITY_MOMS_HEART and effect.SpawnerEntity.SpawnerVariant == 1 then
		local color = "red"
		if Game():GetRoom():GetBackdropType() == BackdropType.WOMB then
			color = "womb red"
		end
		effect:GetSprite():Load("gfx/1000.022_creep (" .. color .. ").anm2", true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.itLivesCreepUpdate, EffectVariant.CREEP_GREEN)