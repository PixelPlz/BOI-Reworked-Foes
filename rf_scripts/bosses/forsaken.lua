local mod = ReworkedFoes

local Settings = {
	NewHealth = 400,

	SummonCount = 3,
	SummonCountChampion = 2,

	Cooldown = 90,
	TransparencyTimer = 10,
	MinTPDistance = 50,

	HideSpeed = 1.5,
	WanderSpeed = 2.5,

	SpitBaseTime = 30,
	MoveSpeed = 5,
	BrimRotationSpeed = 2,
	BrimShotDelay = 30,
}



function mod:ForsakenInit(entity)
	mod:ChangeMaxHealth(entity, Settings.NewHealth)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	entity.CollisionDamage = 0

	entity.ProjectileCooldown = Settings.Cooldown / 2

	-- Black champion
	if entity.SubType == 1 then
		entity.V2 = Vector(2, 140)
	end

	-- Clone
	if entity.Variant == 10 then
		entity:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ForsakenInit, EntityType.ENTITY_FORSAKEN)

function mod:ForsakenUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local data = entity:GetData()
	local room = Game():GetRoom()


	-- Summon a clone
	local function summonClone(position)
		local clone = Isaac.Spawn(entity.Type, 10, entity.SubType, position, Vector.Zero, entity):ToNPC()
		clone.Parent = entity
		clone.State = entity.State
		clone:GetSprite():Play("FadeIn", true)

		clone.I1 = 0
		clone.I2 = 0
		clone.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

		return clone
	end

	-- Clone handler
	if entity.Variant == 10 then
		if entity.Parent then
			if entity.FrameCount <= 2 then
				entity.StateFrame = 0 -- For some reason the clones set their StateFrame to 1 even if I don't do anything?
			end

			entity.MaxHitPoints = entity.Parent.MaxHitPoints
			entity.HitPoints = entity.Parent.HitPoints
			entity.Target = entity.Parent:ToNPC():GetPlayerTarget()

		-- Disappear if it doesn't have a valid parent
		elseif entity.State ~= NpcState.STATE_SUICIDE then
			entity.State = NpcState.STATE_SUICIDE
			sprite:Play("FadeOut", true)
			sprite:SetFrame(8)
		end
	end


	-- Toggle collision
	if sprite:IsEventTriggered("FadeOut") and entity.State ~= NpcState.STATE_SUMMON then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		if SoundEffect.SOUND_FORSAKEN_FADE then
			mod:PlaySound(nil, SoundEffect.SOUND_FORSAKEN_FADE)
		else
			mod:PlaySound(nil, SoundEffect.SOUND_BEAST_GHOST_DASH, 0.75, math.random(97, 103) / 100)
		end

	elseif sprite:IsEventTriggered("FadeIn") then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
	end


	-- Get center position far enough away from the player
	local function getCenterPos()
		local centerPos = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true, true)
		local nearestPlayerPos = Game():GetNearestPlayer(centerPos).Position

		if centerPos:Distance(nearestPlayerPos) < Settings.MinTPDistance then
			local newPos = centerPos + (centerPos - nearestPlayerPos):Resized(Settings.MinTPDistance)
			return room:FindFreePickupSpawnPosition(newPos, 0, true, true)
		else
			return centerPos
		end
	end



	--[[ Bony phase ]]--
	if entity.State == NpcState.STATE_SUMMON then
		-- Appear
		if entity.StateFrame == 0 then
			entity.Velocity = Vector.Zero

			if sprite:IsFinished() then
				entity.StateFrame = 1
				sprite:Play("Summon", true)
			end


		-- Summon Bonies
		elseif entity.StateFrame == 1 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				local summonType = EntityType.ENTITY_BONY
				local summonVariant = 0
				local summonCount = Settings.SummonCount

				-- Black champion
				if entity.SubType == 1 then
					summonType = EntityType.ENTITY_BLACK_BONY
					summonCount = Settings.SummonCountChampion

				-- Red champion
				elseif mod:IsFFChampion(entity, "RedForsaken") then
					summonVariant = FiendFolio.FF.RedBony.Var
					summonCount = Settings.SummonCountChampion
				end

				-- Summon them in a circle
				local angleStep = 360 / summonCount
				local vector = (target.Position - entity.Position):Resized(80)

				for i = 1, summonCount do
					local offset = (angleStep / 2) + (i * angleStep)
					local position = entity.Position + vector:Rotated(offset)
					Isaac.Spawn(summonType, summonVariant, 0, room:FindFreePickupSpawnPosition(position, 0, true, true), Vector.Zero, entity)
				end

				mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
			end

			if sprite:IsFinished() then
				entity.StateFrame = 2
			end


		-- Stay invincible while the Bonies are alive
		elseif entity.StateFrame == 2 then
			mod:WanderAround(entity, Settings.HideSpeed)
			mod:LoopingAnim(sprite, "Faded")

			-- Transparency
			if entity.I2 > 0 then
				sprite.Color = mod.Colors.GhostTransparent
				entity.I2 = entity.I2 - 1
			else
				sprite.Color = Color.Default
			end


			-- Fade in if the Bonies are dead
			local checkType = EntityType.ENTITY_BONY
			if entity.SubType == 1 then
				checkType = EntityType.ENTITY_BLACK_BONY
			end

			if Isaac.CountEntities(entity, checkType, -1, -1) <= 0 then
				entity.StateFrame = 3
				sprite:Play("FadeInAngry", true)
				sprite.Color = Color.Default
			end


		-- Go to idle state
		elseif entity.StateFrame == 3 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(entity, SoundEffect.SOUND_THE_FORSAKEN_LAUGH, 2)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end
		end



	--[[ Idle ]]--
	elseif entity.State == NpcState.STATE_IDLE then
		mod:WanderAround(entity, Settings.WanderSpeed)
		mod:LoopingAnim(sprite, "Idle")

		-- Choose an attack
		if entity.ProjectileCooldown <= 0 then
			entity.State = NpcState.STATE_MOVE
			sprite:Play("FadeOut", true)
		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end



	--[[ Fade away, choose an attack ]]--
	elseif entity.State == NpcState.STATE_MOVE then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsFinished() then
			entity.ProjectileCooldown = Settings.Cooldown
			entity.I1 = 0
			entity.I2 = 0
			entity.StateFrame = 0
			mod:PlaySound(entity, SoundEffect.SOUND_THE_FORSAKEN_LAUGH, 2)

			local attackCount = mod:IsFFChampion(entity, "RedForsaken") and 2 or 3
			local attack = mod:Random(1, attackCount)


			-- Rotating brimstone attack
			if attack == 1 then
				entity.State = NpcState.STATE_ATTACK
				sprite:Play("FadeIn", true)
				entity.Position = getCenterPos()


			-- Clone spit attack
			elseif attack == 2 then
				entity.State = NpcState.STATE_ATTACK2
				sprite:Play("FadeIn", true)

				local offset = mod:Random(359)

				for i = 0, 2 do
					local index = 2 - i
					local position = entity.Position

					-- Black champions orbit the player
					if entity.SubType == 1 then
						position = target.Position + Vector.FromAngle((120 * index) + entity.V1.Y):Resized(entity.V2.Y)

					-- Spawn in a circle around the player
					else
						position = target.Position + Vector.FromAngle(offset + (i * 120)):Resized(200)
						position = room:FindFreePickupSpawnPosition(position, 0, true, true)

						if position:Distance(Game():GetNearestPlayer(position).Position) < 80 then
							position = target.Position + (room:GetCenterPos() - target.Position):Resized(200)
							position = room:FindFreePickupSpawnPosition(position, 0, true, true)
						end
					end

					-- Set timers and positions
					local guy = entity
					if i > 0 then
						guy = summonClone(position)
					end

					guy.Position = position
					guy.I1 = index
					guy.I2 = index * Settings.SpitBaseTime

					-- Orbit stuff for black champion
					if entity.SubType == 1 then
						guy.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
						guy.V1 = Vector(120 * entity.I1, entity.V1.Y + entity.V2.X)
					end
				end


			-- Clone brimstone attack
			elseif attack == 3 then
				entity.State = NpcState.STATE_ATTACK3
				sprite:Play("FadeIntoBlastStart", true)

				-- Get direction and position
				local function getBrimstoneDirection(isClone)
					local directions = {
						{"Up", 	 "Down"},
						{"Left", "Right"}
					}

					-- Get direction
					local horizontalOrVertical = 1
					local firstOrSecond = 1

					if isClone == true then
						horizontalOrVertical = 2
						if target.Position.X > room:GetCenterPos().X then
							firstOrSecond = 2
						end
					else
						if target.Position.Y > room:GetCenterPos().Y then
							firstOrSecond = 2
						end
					end

					local facing = directions[horizontalOrVertical][firstOrSecond]


					-- Get position
					local pos = Vector(room:GetBottomRightPos().X, room:GetCenterPos().Y)
					local I2 = 2

					if facing == "Up" then
						pos = Vector(room:GetCenterPos().X, room:GetBottomRightPos().Y)
						I2 = 3
					elseif facing == "Down" then
						pos = Vector(room:GetCenterPos().X, room:GetTopLeftPos().Y)
						I2 = 1
					elseif facing == "Right" then
						pos = Vector(room:GetTopLeftPos().X, room:GetCenterPos().Y)
						I2 = 0
					end

					local returnTable = {}
					table.insert(returnTable, facing)
					table.insert(returnTable, room:FindFreePickupSpawnPosition(pos, 0, true, true))
					table.insert(returnTable, I2)
					return returnTable
				end

				local mainTable = getBrimstoneDirection(false)
				data.facing	= mainTable[1]
				entity.Position = mainTable[2]
				entity.I2 = mainTable[3]

				local cloneTable = getBrimstoneDirection(true)
				local clone = summonClone(cloneTable[2])
				clone:GetData().facing = cloneTable[1]
				clone.I2 = cloneTable[3]
				clone:GetSprite():Play("FadeIntoBlastStart", true)
			end
		end



	--[[ Rotating brimstone attack ]]--
	elseif entity.State == NpcState.STATE_ATTACK then
		entity.Velocity = mod:StopLerp(entity.Velocity)
		mod:IgnoreKnockoutDrops(entity)

		-- Appear
		if entity.StateFrame == 0 then
			if sprite:IsFinished() then
				entity.StateFrame = 1
				sprite:Play("BlastStart", true)
				mod:PlaySound(entity, SoundEffect.SOUND_LOW_INHALE, 1.25)
			end


		-- Charge up lasers
		elseif entity.StateFrame == 1 then
			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(entity, SoundEffect.SOUND_THE_FORSAKEN_SCREAM, 2)

				if entity.SubType == 1 then
					mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_START, 1.1)
				end
			end

			if sprite:IsFinished() then
				entity.StateFrame = 2
				entity.ProjectileDelay = 0

				-- Get the rotation direction
				entity.I2 = mod:RandomSign()

				for i, other in pairs( Isaac.FindByType(entity.Type, entity.Variant) ) do
					other = other:ToNPC()

					if other.Index ~= entity.Index
					and other.State == entity.State and other.I2 ~= 0 then
						entity.I2 = other.I2
						break
					end
				end

				-- Red champion
				if mod:IsFFChampion(entity, "RedForsaken") then
					entity.TargetPosition = target.Position - entity.Position

				-- Regular
				elseif entity.SubType == 0 then
					entity.ProjectileDelay = Settings.BrimShotDelay

					local laserPos = entity.Position - Vector(0, 40)
					local targetVector = target.Position - laserPos

					for i = 0, 2 do
						local angle = targetVector:GetAngleDegrees() + (i * 120) - 60
						data.brim = EntityLaser.ShootAngle(LaserVariant.THICK_RED, laserPos, angle, -1, Vector.Zero, entity)
						data.brim:SetActiveRotation(20, entity.I2 * 180, entity.I2 * Settings.BrimRotationSpeed, 10)
					end
				end
			end


		-- Shooting lasers
		elseif entity.StateFrame == 2 then
			mod:LoopingAnim(sprite, "BlastingDown")

			-- Particles
			if not mod:IsFFChampion(entity, "RedForsaken") and entity:IsFrame(2, 0) then
				local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HAEMO_TRAIL, 0, entity.Position, mod:RandomVector(8), entity):ToEffect()
				local scaler = math.random(70, 90) / 100
				trail.SpriteScale = Vector(scaler, scaler)
				trail.SpriteOffset = Vector(0, -35) + trail.Velocity:Resized(20)
				trail.DepthOffset = entity.DepthOffset - 10

				if entity.SubType == 1 then
					trail:GetSprite().Color = mod.Colors.BlueFireShot
				else
					trail:GetSprite().Color = Color(1,1,1, 0.5, 0.5,0,0)
				end
				trail:Update()
			end


			-- Shots
			if entity.ProjectileDelay <= 0 then
				local params = ProjectileParams()


				-- Black champion fires
				if entity.SubType == 1 then
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.1
					params.CircleAngle = entity.I1 * (entity.I2 * 35)

					params.BulletFlags = ProjectileFlags.FIRE
					params.Variant = ProjectileVariant.PROJECTILE_FIRE
					params.Color = mod.Colors.BlueFire

					entity:FireProjectiles(entity.Position, Vector(8, 4), 9, params)
					entity.ProjectileDelay = 4


				-- Red champion shots
				elseif mod:IsFFChampion(entity, "RedForsaken") then
					params.BulletFlags = params.BulletFlags | ProjectileFlags.HIT_ENEMIES
					params.Scale = params.Scale * 1.4
					params.Damage = 1
					params.CurvingStrength = params.CurvingStrength + 0.002
					params.FallingAccelModifier = params.FallingAccelModifier - 0.0625

					if entity.I2 == 1 then
						params.BulletFlags = params.BulletFlags | ProjectileFlags.CURVE_RIGHT
					else
						params.BulletFlags = params.BulletFlags | ProjectileFlags.CURVE_LEFT
					end

					local offset = entity.I1 * 19 * entity.I2

					for i = -1, 1, 2 do
						local velocity = entity.TargetPosition:Rotated(i * 90 + offset)
						entity:FireProjectiles(entity.Position, velocity:Resized(10), 0, params)
					end

					mod:PlaySound(entity, SoundEffect.SOUND_BLOODSHOOT)
					entity.ProjectileDelay = 8


				-- Regular
				else
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.1
					params.CircleAngle = entity.I1 * mod:DegreesToRadians(30)

					params.Variant = ProjectileVariant.PROJECTILE_HUSH
					params.Color = mod.Colors.BrimShot
					params.Scale = 1.25

					mod:FireProjectiles(entity, entity.Position, Vector(8, 6), 9, params, Color.Default)
					mod:PlaySound(entity, SoundEffect.SOUND_FIRE_RUSH, 0.8)
					entity.ProjectileDelay = Settings.BrimShotDelay
				end

				entity.I1 = entity.I1 + 1
			else
				entity.ProjectileDelay = entity.ProjectileDelay - 1
			end


			-- Stop
			if (entity.SubType == 1 					and entity.I1 >= 18) -- Black
			or (mod:IsFFChampion(entity, "RedForsaken") and entity.I1 >= 14) -- Red
			or (entity.SubType == 0 					and (not data.brim or not data.brim:Exists())) then
				entity.StateFrame = 3
				sprite:Play("BlastEnd", true)

				if entity.SubType == 1 then
					mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_END, 1.1)
				end
			end


		-- Finish attack
		elseif entity.StateFrame == 3 then
			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end
		end



	--[[ Clone spit attack ]]--
	elseif entity.State == NpcState.STATE_ATTACK2 then
		-- Orbit parent
		if entity.SubType == 1 and entity.StateFrame < 3 then
			entity.V1 = Vector(120 * entity.I1, (entity.V1.Y + entity.V2.X) % 360) -- Rotation offset / Current rotation
			local offset = Vector.FromAngle(entity.V1.X + entity.V1.Y):Resized(entity.V2.Y)
			entity.Position = mod:Lerp(entity.Position, target.Position + offset, 0.1)
			entity.Velocity = target.Velocity

		else
			entity.Velocity = mod:StopLerp(entity.Velocity)
		end


		-- Appear
		if entity.StateFrame == 0 then
			if sprite:IsFinished() then
				entity.StateFrame = 1
			end


		-- Wait for its turn
		elseif entity.StateFrame == 1 then
			mod:LoopingAnim(sprite, "Idle")

			if entity.I2 <= 0 then
				entity.StateFrame = 2
				mod:PlaySound(entity, SoundEffect.SOUND_MOUTH_FULL)

				if entity.Variant == 10 or entity.SubType == 1 then
					sprite:Play("ShootClone", true)
				else
					sprite:Play("Shoot", true)
				end

			else
				entity.I2 = entity.I2 - 1
			end


		-- Shoot
		elseif entity.StateFrame == 2 then
			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_BONE

				-- Black champion
				if entity.SubType == 1 then
					params.BulletFlags = (ProjectileFlags.FIRE | ProjectileFlags.BLUE_FIRE_SPAWN)
					params.Scale = 1.5
					params.Color = mod.Colors.BlackBony
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(11), 0, params)

				-- Red champion
				elseif mod:IsFFChampion(entity, "RedForsaken") then
					params.Spread = 1.5
					local velocity = (target.Position - entity.Position):Resized(8)
					local projectiles = entity:FireProjectilesEx(entity.Position, velocity, 3, params)

					for i, projectile in pairs(projectiles) do
						local projectileData = FiendFolio:GetEntityData(projectile)
						projectileData.projType = "RedBony"
						projectileData.NumBounces = 4

						projectile.Color = Color(173/255, 24/255, 24/255, 1)
						projectile.FallingSpeed = -10
						projectile.FallingAccel = 1.5
					end

				-- Regular
				else
					params.Spread = 1 + entity.I1 * 0.15

					local projectileMode = 3 + entity.I1
					local velocity = (target.Position - entity.Position):Resized(11 - entity.I1)
					mod:FireProjectiles(entity, entity.Position, velocity, projectileMode, params, mod.Colors.GhostTrail)
				end

				mod:PlaySound(entity, SoundEffect.SOUND_GHOST_SHOOT, 1.25)
			end

			-- Finish attack
			if sprite:IsFinished() then
				if entity.Variant == 10 then
					entity:Remove()

				else
					-- Black champion should teleport to the center of the room
					if entity.SubType == 1 then
						entity.StateFrame = 3
						sprite:Play("FadeIn", true)
						mod:PlaySound(entity, SoundEffect.SOUND_THE_FORSAKEN_LAUGH, 2)

						entity.Position = getCenterPos()
						entity.Velocity = Vector.Zero
						entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					else
						entity.State = NpcState.STATE_IDLE
					end
				end
			end


		-- Black champion teleport
		elseif entity.StateFrame == 3 then
			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end
		end



	--[[ Clone brimstone attack ]]--
	elseif entity.State == NpcState.STATE_ATTACK3 then
		-- Movement
		if entity.StateFrame == 1 and (not sprite:WasEventTriggered("Shoot") or entity.SubType == 1)
		or (entity.SubType == 1 and entity.StateFrame == 2) then
			-- Get target position
			local moveto = target.Position
			if entity.Variant == 10 then
				moveto = Vector(entity.Position.X, target.Position.Y + 25)
			else
				moveto = Vector(target.Position.X, entity.Position.Y)
			end

			-- Move slower while firing
			local baseSpeed = Settings.MoveSpeed
			if sprite:WasEventTriggered("Shoot") or entity.StateFrame == 2 then
				baseSpeed = Settings.MoveSpeed / 2
			end

			-- Move to position
			local distance = entity.Position:Distance(moveto)
			local speed = math.min(distance, baseSpeed)
			entity.Velocity = mod:Lerp(entity.Velocity, (moveto - entity.Position):Resized(speed), 0.25)

		else
			entity.Velocity = mod:StopLerp(entity.Velocity)
		end


		-- Appear
		if entity.StateFrame == 0 then
			if sprite:IsFinished() then
				entity.StateFrame = 1
				mod:PlaySound(entity, SoundEffect.SOUND_LOW_INHALE, 1.5)

				if data.facing == "Left" or data.facing == "Right" then
					sprite:Play("BlastStartSide", true)
					if data.facing == "Left" then
						sprite.FlipX = true
					end
				else
					sprite:Play("BlastStart" .. data.facing, true)
				end
			end


		-- Move towards target, charge laser
		elseif entity.StateFrame == 1 then
			if sprite:IsEventTriggered("Shoot") then
				if entity.SubType == 1 then
					mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_START, 1.1)
				else
					mod:QuickTracer(entity, entity.I2 * 90, Vector(0, -50), 6, 3)
				end
			end

			if sprite:IsFinished() then
				entity.StateFrame = 2
				entity.I1 = 0

				if entity.SubType == 0 then
					entity.Velocity = Vector.Zero

					local angle = entity.I2 * 90
					local pos = entity.Position - Vector(0, 50) + Vector.FromAngle(angle):Resized(10)
					data.brim = EntityLaser.ShootAngle(LaserVariant.THICK_RED, pos, angle, 30, Vector.Zero, entity)

					if data.facing == "Down" then
						data.brim.DepthOffset = entity.DepthOffset + 60
					end
				end
				mod:PlaySound(entity, SoundEffect.SOUND_GHOST_ROAR, 1.75)
			end


		-- Shooting laser
		elseif entity.StateFrame == 2 then
			if data.facing == "Left" or data.facing == "Right" then
				mod:LoopingAnim(sprite, "BlastingSide")
			else
				mod:LoopingAnim(sprite, "Blasting" .. data.facing)
			end

			-- Black champion shoots a stream of fires
			if entity.SubType == 1 then
				if entity.ProjectileDelay <= 0 then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_FIRE
					params.Color = mod.Colors.BlueFire
					params.BulletFlags = ProjectileFlags.FIRE
					entity:FireProjectiles(entity.Position - Vector(0, 18) + Vector.FromAngle(entity.I2 * 90):Resized(10), Vector.FromAngle(entity.I2 * 90 + mod:Random(-5, 5)):Resized(9), 0, params)

					entity.I1 = entity.I1 + 1
					entity.ProjectileDelay = 3

				else
					entity.ProjectileDelay = entity.ProjectileDelay - 1
				end
			end

			-- Stop
			if (entity.SubType == 0 and (not data.brim or not data.brim:Exists()))
			or (entity.SubType == 1 and entity.I1 >= 12) then
				entity.StateFrame = 3

				if data.facing == "Left" or data.facing == "Right" then
					sprite:Play("BlastEndSide", true)
				else
					sprite:Play("BlastEnd" .. data.facing, true)
				end

				if entity.SubType == 1 then
					mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_END, 1.1)
				end
			end


		-- Finish attack
		elseif entity.StateFrame == 3 then
			if sprite:IsEventTriggered("Shoot") then
				sprite.FlipX = false
			end

			if sprite:IsFinished() then
				if entity.Variant == 10 then
					entity:Remove()

				else
					entity.StateFrame = 4
					sprite:Play("FadeIn", true)
					mod:PlaySound(nil, SoundEffect.SOUND_THE_FORSAKEN_LAUGH, 2)
					entity.Position = getCenterPos()
					entity.Velocity = Vector.Zero
				end
			end


		-- Teleport to the center of the room
		elseif entity.StateFrame == 4 then
			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end
		end



	--[[ Clone fade away ]]--
	elseif entity.State == NpcState.STATE_SUICIDE then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsFinished() then
			entity:Remove()
		end


	-- Delirium fix
	elseif data.wasDelirium then
		entity.State = NpcState.STATE_MOVE
		sprite:Play("FadeOut", true)
	end

	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.ForsakenUpdate, EntityType.ENTITY_FORSAKEN)

function mod:ForsakenDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	local entity = entity:ToNPC()

	-- Bony phase
	if entity.State == NpcState.STATE_APPEAR or (entity.State == NpcState.STATE_SUMMON and entity.StateFrame < 3) then
		entity.I2 = Settings.TransparencyTimer
		return false

	-- Prevent champion's Black Bonies from pretty much killing him if killed next to him
	elseif damageSource.SpawnerType == entity.Type or damageSource.SpawnerType == EntityType.ENTITY_BLACK_BONY then
		return false

	-- Clones
	elseif entity.Variant == 10 and entity.Parent then
		entity.Parent:TakeDamage(damageAmount, damageFlags + DamageFlag.DAMAGE_COUNTDOWN, damageSource, 1)
		entity:SetColor(mod.Colors.DamageFlash, 2, 0, false, true)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.ForsakenDMG, EntityType.ENTITY_FORSAKEN)

function mod:ForsakenCollision(entity, target, bool)
	if target.SpawnerType == entity.Type then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.ForsakenCollision, EntityType.ENTITY_FORSAKEN)