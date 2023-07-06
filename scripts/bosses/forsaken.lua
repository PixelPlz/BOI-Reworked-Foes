local mod = BetterMonsters

local Settings = {
	NewHealth = 350,
	Cooldown = 90,
	TransparencyTimer = 10,

	HideSpeed = 1.5,
	WanderSpeed = 2.25,

	SpitBaseTime = 30,
	MoveSpeed = 5,
	BrimRotationSpeed = 2,
	BrimShotDelay = 30,
}



function mod:forsakenInit(entity)
	entity.MaxHitPoints = Settings.NewHealth
	entity.HitPoints = entity.MaxHitPoints
	entity.ProjectileCooldown = Settings.Cooldown / 2
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

	if entity.SubType == 1 then
		entity.V2 = Vector(2, 140)
	end

	if entity.Variant == 10 then
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		entity:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.forsakenInit, EntityType.ENTITY_FORSAKEN)

function mod:forsakenUpdate(entity)
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
			if entity.FrameCount == 2 then
				entity.StateFrame = 0 -- For some reasons the clones set their StateFrame to 1 even if I don't do anything???
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
		mod:PlaySound(nil, SoundEffect.SOUND_BEAST_GHOST_DASH, 0.8)

	elseif sprite:IsEventTriggered("FadeIn") then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
	end


	-- Particles
	local color = Color.Default
	if entity.SubType == 0 then
		color = IRFcolors.GhostTrail
	end
	mod:SmokeParticles(entity, Vector(0, -40), 25, Vector(100, 120), color)


	-- Bony phase
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
				if entity.SubType == 1 then
					summonType = EntityType.ENTITY_BLACK_BONY
				end
				for i = 0, 2 do
					local angle = (target.Position - entity.Position):GetAngleDegrees() + (i * 120) - 60
					local position = entity.Position + Vector.FromAngle(angle):Resized(80)
					Isaac.Spawn(summonType, 0, 0, room:FindFreePickupSpawnPosition(position, 0, true, true), Vector.Zero, entity)
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
				sprite.Color = IRFcolors.GhostTransparent
				entity.I2 = entity.I2 - 1
			else
				sprite.Color = Color.Default
			end


			-- Fade in if the bonies are dead
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


	-- Idle
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


	-- Fade away, choose an attack
	elseif entity.State == NpcState.STATE_MOVE then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsFinished() then
			entity.ProjectileCooldown = Settings.Cooldown
			entity.I1 = 0
			entity.I2 = 0
			entity.StateFrame = 0

			mod:PlaySound(entity, SoundEffect.SOUND_THE_FORSAKEN_LAUGH, 2)
			local attack = mod:Random(1, 3)

			-- Rotating brimstone attack
			if attack == 1 then
				entity.State = NpcState.STATE_ATTACK
				sprite:Play("FadeIn", true)
				entity.Position = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true, true)


			-- Clone spit attack
			elseif attack == 2 then
				entity.State = NpcState.STATE_ATTACK2
				sprite:Play("FadeIn", true)
				local offset = mod:Random(359)

				for i = 0, 2 do
					local index = 2 - i
					local position = entity.Position

					-- Get positions
					-- Black champions orbit the player
					if entity.SubType == 1 then
						position = target.Position + Vector.FromAngle((120 * index) + entity.V1.Y):Resized(entity.V2.Y)

					-- In a circle around the player
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

					if entity.SubType == 1 then
						guy.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
						guy.V1 = Vector((120 * entity.I1), entity.V1.Y + entity.V2.X)
					end
				end


			-- Clone brimstone attack
			elseif attack == 3 then
				entity.State = NpcState.STATE_ATTACK3
				sprite:Play("FadeIntoBlastStart", true)

				-- Get direction and position
				local function getBrimstoneDirection(isClone)
					local directions = {
						{"Up", "Down"},
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


	-- Rotating brimstone attack
	elseif entity.State == NpcState.STATE_ATTACK then
		entity.Velocity = mod:StopLerp(entity.Velocity)
		entity.Position = mod:Lerp(entity.Position, room:GetCenterPos(), 0.25)

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
				entity.ProjectileDelay = Settings.BrimShotDelay - (entity.SubType * Settings.BrimShotDelay)

				-- Rotation direction
				entity.I2 = mod:RandomSign()

				if entity.SubType == 0 then
					for i = 0, 2 do
						local angle = (target.Position - (entity.Position - Vector(0, 40))):GetAngleDegrees() + (i * 120) - 60
						local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position - Vector(0, 40), angle, -1, Vector.Zero, entity), entity}
						data.brim = laser_ent_pair.laser
						data.brim:SetActiveRotation(20, entity.I2 * 180, entity.I2 * Settings.BrimRotationSpeed, 10)
					end
				end
			end

		-- Shooting lasers
		elseif entity.StateFrame == 2 then
			mod:LoopingAnim(sprite, "BlastingDown")

			-- Particles
			if entity:IsFrame(2, 0) then
				local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HAEMO_TRAIL, 0, entity.Position, mod:RandomVector(8), entity):ToEffect()
				local scaler = math.random(70, 90) / 100
				trail.SpriteScale = Vector(scaler, scaler)
				trail.SpriteOffset = Vector(0, -35) + trail.Velocity:Resized(20)
				trail.DepthOffset = entity.DepthOffset - 10

				if entity.SubType == 1 then
					trail:GetSprite().Color = IRFcolors.BlueFireShot
				else
					trail:GetSprite().Color = Color(1,1,1, 0.5, 0.5,0,0)
				end

				trail:Update()
			end


			-- Shots
			if entity.ProjectileDelay <= 0 then
				local params = ProjectileParams()
				params.FallingSpeedModifier = 1
				params.FallingAccelModifier = -0.1

				-- Champion fires
				if entity.SubType == 1 then
					params.Variant = ProjectileVariant.PROJECTILE_FIRE
					params.Color = IRFcolors.BlueFire
					params.BulletFlags = ProjectileFlags.FIRE
					params.CircleAngle = entity.I1 * (entity.I2 * 35)
					entity:FireProjectiles(entity.Position, Vector(8, 4), 9, params)

					entity.I1 = entity.I1 + 1
					entity.ProjectileDelay = 4

				-- Regular
				else
					params.Variant = ProjectileVariant.PROJECTILE_HUSH
					params.Color = IRFcolors.BrimShot
					params.Scale = 1.25
					mod:FireProjectiles(entity, entity.Position, Vector(8, 8), 8, params, Color.Default)

					mod:PlaySound(entity, SoundEffect.SOUND_FIRE_RUSH, 0.8)
					entity.ProjectileDelay = Settings.BrimShotDelay
				end

			else
				entity.ProjectileDelay = entity.ProjectileDelay - 1
			end


			if (entity.SubType == 0 and (not data.brim or not data.brim:Exists())) or (entity.SubType == 1 and entity.I1 >= 18) then
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


	-- Clone spit attack
	elseif entity.State == NpcState.STATE_ATTACK2 then
		if entity.SubType == 1 and entity.StateFrame < 3 then
			-- Orbit parent
			entity.V1 = Vector((120 * entity.I1), entity.V1.Y + entity.V2.X) -- Rotation offset / Current rotation
			if entity.V1.Y >= 360 then
				entity.V1 = Vector(entity.V1.X, entity.V1.Y - 360)
			end
			entity.Position = mod:Lerp(entity.Position, target.Position + Vector.FromAngle(entity.V1.X + entity.V1.Y):Resized(entity.V2.Y), 0.1)
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
				if entity.Variant == 10 or entity.SubType == 1 then
					sprite:Play("ShootClone", true)
				else
					sprite:Play("Shoot", true)
				end
				mod:PlaySound(entity, SoundEffect.SOUND_MOUTH_FULL)

			else
				entity.I2 = entity.I2 - 1
			end

		-- Shoot
		elseif entity.StateFrame == 2 then
			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_BONE
				
				if entity.SubType == 0 then
					mod:FireProjectiles(entity, entity.Position, (target.Position - entity.Position):Resized(11 - entity.I1), 3 + entity.I1, params, IRFcolors.GhostTrail)

				elseif entity.SubType == 1 then
					params.BulletFlags = (ProjectileFlags.FIRE | ProjectileFlags.BLUE_FIRE_SPAWN)
					params.Scale = 1.5
					params.Color = IRFcolors.BlackBony
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(11), 0, params)
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

						entity.Position = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true, true)
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


	-- Clone brimstone attack
	elseif entity.State == NpcState.STATE_ATTACK3 then
		-- Movement
		if entity.StateFrame == 1 or (entity.SubType == 1 and entity.StateFrame == 2) then
			-- Get target position
			local moveto = target.Position
			if entity.Variant == 10 then
				moveto = Vector(entity.Position.X, target.Position.Y + 25)
			else
				moveto = Vector(target.Position.X, entity.Position.Y)
			end

			-- Move slower while firing
			local speed = Settings.MoveSpeed
			if entity.StateFrame == 2 then
				speed = Settings.MoveSpeed / 2
			end

			-- Move to position
			if entity.Position:Distance(moveto) > 10 then
				entity.Velocity = mod:Lerp(entity.Velocity, (moveto - entity.Position):Resized(speed), 0.25)
			else
				entity.Velocity = mod:StopLerp(entity.Velocity)
			end

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
					mod:QuickTracer(entity, entity.I2 * 90, Vector(0, -50), 15, 1, 2)
				end
			end

			if sprite:IsFinished() then
				entity.StateFrame = 2
				entity.I1 = 0

				if entity.SubType == 0 then
					entity.Velocity = Vector.Zero
					local angle = entity.I2 * 90
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position - Vector(0, 50) + Vector.FromAngle(angle):Resized(10), angle, 20, Vector.Zero, entity), entity}
					data.brim = laser_ent_pair.laser

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

			if entity.SubType == 1 then
				if entity.ProjectileDelay <= 0 then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_FIRE
					params.Color = IRFcolors.BlueFire
					params.BulletFlags = ProjectileFlags.FIRE
					entity:FireProjectiles(entity.Position - Vector(0, 18) + Vector.FromAngle(entity.I2 * 90):Resized(10), Vector.FromAngle(entity.I2 * 90 + mod:Random(-5, 5)):Resized(9), 0, params)

					entity.I1 = entity.I1 + 1
					entity.ProjectileDelay = 3

				else
					entity.ProjectileDelay = entity.ProjectileDelay - 1
				end
			end

			if (entity.SubType == 0 and (not data.brim or not data.brim:Exists())) or (entity.SubType == 1 and entity.I1 >= 12) then
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
					entity.Position = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true, true)
					entity.Velocity = Vector.Zero
				end
			end

		-- Teleport to the center of the room
		elseif entity.StateFrame == 4 then
			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end
		end


	-- Clone fade away
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
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.forsakenUpdate, EntityType.ENTITY_FORSAKEN)

function mod:forsakenDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	-- Bony phase
	if target:ToNPC().State == NpcState.STATE_APPEAR or (target:ToNPC().State == NpcState.STATE_SUMMON and target:ToNPC().StateFrame < 3) then
		target:ToNPC().I2 = Settings.TransparencyTimer
		return false

	-- Prevent champion's Black Bonies from pretty much killing him if killed next to him
	elseif damageSource.SpawnerType == target.Type or damageSource.SpawnerType == EntityType.ENTITY_BLACK_BONY then
		return false

	-- Clones
	elseif target.Variant == 10 and target.Parent then
		if target.HitPoints - damageAmount <= 0 then
			return false
		else
			target.Parent:TakeDamage(damageAmount, damageFlags + DamageFlag.DAMAGE_COUNTDOWN, damageSource, 5)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.forsakenDMG, EntityType.ENTITY_FORSAKEN)

function mod:forsakenCollide(entity, target, bool)
	if target.SpawnerType == entity.Type then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.forsakenCollide, EntityType.ENTITY_FORSAKEN)