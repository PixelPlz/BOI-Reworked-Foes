local mod = BetterMonsters
local game = Game()

local Settings = {
	MoveSpeed = 4,
	ChargeSpeed = 54,
	AngrySpeed = 64,
	ChargeCooldown = 30,
	StunTime = 20,
	SideRange = 40,
	FrontRange = 320,
	CrashScreenShake = 12,
	MinChargeTime = 15,

	NewHealth = 500,
	Cooldown = {80, 110},
	ShotSpeed = 12,
	Phase2Shots = 2,
	BlackLaserOffset = -35,
	BlackShotSpeed = 10
}

local States = {
	Appear = 0,
	Idle = 1,
	Attack1 = 2,
	Attack2 = 3,
	Transition = 4,
}

local effectColor = Color(0.5,0.5,0.7, 1, 0.1,0.1,0.25)



--[[ Mask ]]--
function mod:maskInfamyReplace(entity)
	local data = entity:GetData()

	data.state = States.Appear
	entity.ProjectileCooldown = Settings.ChargeCooldown / 2
	data.place = Isaac:GetRandomPosition()
	entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_NO_STATUS_EFFECTS)

	if entity.SubType == 1 then
		entity.SplatColor = effectColor
	elseif entity.SubType == 2 then
		entity.SplatColor = FiendFolio.ColorLemonYellow
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.maskInfamyReplace, EntityType.ENTITY_MASK_OF_INFAMY)

function mod:maskInfamyUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()
	local target = entity:GetPlayerTarget()


	if not data.state or data.state == States.Appear then
		data.state = States.Idle

	elseif data.state == States.Idle or data.state == States.Attack1 or data.state == States.Attack2 then
		local prefix = "Sad"
		local speed = Settings.ChargeSpeed
		if entity.I1 == 1 then
			prefix = "Angry"
			speed = Settings.AngrySpeed
		end


		if data.state == States.Idle then
			-- Movement
			if entity.Position:Distance(data.place) < 2 or entity.Velocity:Length() < 1 or not entity.Pathfinder:HasPathToPos(data.place, false) then
				data.place = Isaac:GetRandomPosition()
			end
			entity.Pathfinder:FindGridPath(data.place, Settings.MoveSpeed / 6, 500, false)
			entity.Pathfinder:UpdateGridIndex()

			-- Get animation direction
			local angleDegrees = entity.Velocity:GetAngleDegrees()
			if angleDegrees > -45 and angleDegrees < 45 then
				data.facing = "Right"
			elseif angleDegrees >= 45 and angleDegrees <= 135 then
				data.facing = "Down"
			elseif angleDegrees < -45 and angleDegrees > -135 then
				data.facing = "Up"
			else
				data.facing = "Left"
			end

			-- Charge
			if entity.ProjectileCooldown <= 0 and game:GetRoom():CheckLine(entity.Position, target.Position, 0, 0, false, false)
			and entity.Position:Distance(target.Position) <= Settings.FrontRange then
				if (entity.Position.X <= target.Position.X + Settings.SideRange and entity.Position.X >= target.Position.X - Settings.SideRange)
				or (entity.Position.Y <= target.Position.Y + Settings.SideRange and entity.Position.Y >= target.Position.Y - Settings.SideRange) then
					if not ((data.facing == "Left" and target.Position.X > entity.Position.X + Settings.SideRange)
					or (data.facing == "Right" and target.Position.X < entity.Position.X + Settings.SideRange)
					or (data.facing == "Up" and target.Position.Y > entity.Position.Y + Settings.SideRange)
					or (data.facing == "Down" and target.Position.Y < entity.Position.Y + Settings.SideRange)) then
						data.state = States.Attack1
						entity.Velocity = Vector.Zero
						entity:PlaySound(SoundEffect.SOUND_BOSS_LITE_ROAR, 1, 0, false, 1)

						angleDegrees = (target.Position - entity.Position):GetAngleDegrees()
						if angleDegrees > -45 and angleDegrees < 45 then
							data.facing = "Right"
						elseif angleDegrees >= 45 and angleDegrees <= 135 then
							data.facing = "Down"
						elseif angleDegrees < -45 and angleDegrees > -135 then
							data.facing = "Up"
						else
							data.facing = "Left"
						end
					end
				end
			
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Charging
		elseif data.state == States.Attack1 then
			-- Get direction
			local angle = 0
			if data.facing == "Left" then
				angle = 180
			elseif data.facing == "Down" then
				angle = 90
			elseif data.facing == "Up" then
				angle = -90
			end
			entity.Velocity = (entity.Velocity + (Vector.FromAngle(angle) * speed - entity.Velocity) * 0.015)
			entity.I2 = entity.I2 + 1 -- Only crash if it charged for long enough

			-- Crash into wall
			if entity:CollidesWithGrid() then
				if entity.I2 >= Settings.MinChargeTime then
					data.state = States.Attack2
					entity.ProjectileCooldown = Settings.StunTime + (entity.I1 * (Settings.StunTime / 2))
					SFXManager():Play(SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1)
					game:ShakeScreen(Settings.CrashScreenShake)

					-- Rock shots
					if entity.SubType == 0 or entity.I1 == 1 then
						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_ROCK
						entity:FireBossProjectiles(10 - (entity.I1 * 2), entity.Position + -(Vector.FromAngle(angle) * 20), 1.5, params)

						if entity.SubType == 0 and entity.I1 == 1 then
							entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed - 1, 0), 8, params)
						end
					end

				else
					data.state = States.Idle
					entity.ProjectileCooldown = Settings.ChargeCooldown / 2
				end
				entity.I2 = 0
			end
			
			
			if FiendFolio and entity.SubType == 2 and entity:IsFrame(2, 0) and entity.I2 >= 7 then
				local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_YELLOW, 0, entity.Position, Vector.Zero, entity):ToEffect()
				creep.Scale = 1.15
				creep:Update()
			end


		-- Stunned
		elseif data.state == States.Attack2 then
			entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)

			if entity.ProjectileCooldown <= 0 then
				data.state = States.Idle
				entity.ProjectileCooldown = Settings.ChargeCooldown
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end
		end


		-- Walking animation
		if not sprite:IsPlaying(prefix .. "Mask" .. data.facing) then
			sprite:Play(prefix .. "Mask" .. data.facing, true)
		end


	-- Transition to 2nd phase
	elseif data.state == States.Transition then
		entity.Velocity = Vector.Zero
		if not sprite:IsPlaying("AngryMaskAppear") then
			sprite:Play("AngryMaskAppear", true)
			sprite:SetFrame(6)
			entity:PlaySound(SoundEffect.SOUND_MOUTH_FULL, 1, 0, false, 1.025)
		end

		if sprite:GetFrame() == 15 then
			data.state = States.Idle
			entity.I1 = 1
		end
	end


	-- Die if the heart is dead
	if entity.FrameCount > 1 then
		if not entity.Parent or entity.Parent:IsDead() then
			entity:Kill()
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.maskInfamyUpdate, EntityType.ENTITY_MASK_OF_INFAMY)

function mod:maskInfamyDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.maskInfamyDMG, EntityType.ENTITY_MASK_OF_INFAMY)

function mod:maskInfamyCollide(entity, target, bool)
	if target.Type == EntityType.ENTITY_HEART_OF_INFAMY then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.maskInfamyCollide, EntityType.ENTITY_MASK_OF_INFAMY)



--[[ Heart ]]--
function mod:heartInfamyReplace(entity)
	local data = entity:GetData()
	
	data.state = States.Appear
	entity.ProjectileCooldown = Settings.Cooldown[1]
	entity.MaxHitPoints = Settings.NewHealth
	entity.HitPoints = entity.MaxHitPoints
	
	if entity.SubType == 1 then
		entity.SplatColor = effectColor
	elseif entity.SubType == 2 then
		entity.SplatColor = FiendFolio.ColorLemonYellow
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.heartInfamyReplace, EntityType.ENTITY_HEART_OF_INFAMY)

function mod:heartInfamyUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()
	local target = entity:GetPlayerTarget()


	if not data.state or data.state == States.Appear then
		data.state = States.Idle
		if entity.Child then
			entity.Child.Parent = entity
		end
	
	elseif data.state == States.Idle then
		entity.Pathfinder:MoveRandomlyBoss(false)
		entity.Velocity = entity.Velocity * 0.925

		local suffix = ""
		if entity.I1 == 1 then
			suffix = "Alt"
		end
		if not sprite:IsPlaying("HeartBeat" .. suffix) then
			sprite:Play("HeartBeat" .. suffix, true)
		end
		
		-- Heart beat
		if sprite:IsEventTriggered("Shoot") and not entity.SubType == 2 then
			entity:PlaySound(SoundEffect.SOUND_HEARTBEAT_FASTEST, 1.15, 0, false, 1)
		end

		-- Decide attack
		if entity.ProjectileCooldown <= 0 then
			local whichAttack = math.random(1, 2)
			if entity.SubType == 1 then
				whichAttack = 2
			end
			
			if whichAttack == 1 then
				data.state = States.Attack1
			elseif whichAttack == 2 then
				data.state = States.Attack2
			end
		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end


	-- Ground slam
	elseif data.state == States.Attack1 then
		entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
		if not sprite:IsPlaying("HeartAttack") and not sprite:IsPlaying("HeartAttackAlt") then
			if entity.I1 == 0 then
				sprite:Play("HeartAttack", true)
			elseif entity.I1 == 1 then
				sprite:Play("HeartAttackAlt", true)
			end
		end


		if sprite:IsEventTriggered("Jump") then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			entity:PlaySound(SoundEffect.SOUND_HEARTOUT, 1, 0, false, 1)
		
		elseif sprite:IsEventTriggered("GetPos") then
			entity.Position = target.Position


		elseif sprite:IsEventTriggered("Shoot") then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			SFXManager():Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1 + (entity.I1 * 0.25))

			local params = ProjectileParams()
			-- FF kidney champion
			if FiendFolio and entity.SubType == 2 then
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_YELLOW, 0, entity.Position, Vector.Zero, entity):ToEffect().Scale = 2
				params.Color = FiendFolio.ColorLemonYellow
				params.FallingAccelModifier = 0.075

				for i = 0, 2 do
					params.Scale = 2
					if i > 0 then
						params.Scale = 1.25
					end
					entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed - (i * 2), 4), 6, params)
				end

				for i = 0, 2 do
					params.Scale = 1.75
					if i > 0 then
						params.Scale = 1
					end
					entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed - 3 - (i * 2), 4), 7, params)
				end

			else
				params.CircleAngle = 0.41
				params.Scale = 1.5
				entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed - 5, 8), 9, params)

				params.Scale = 1.25
				entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 0), 8, params)
				
				-- Creep for jump attack
				if sprite:IsPlaying("HeartAttackAlt") then
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position, Vector.Zero, entity):ToEffect().Scale = 1.5
					for i = 0, 8 do
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position + (Vector.FromAngle(i * 45) * 40), Vector.Zero, entity):ToEffect().Scale = 1.5
					end
				-- Slam effect
				else
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity).SpriteScale = Vector(0.75, 0.75)
				end
			end


		elseif sprite:IsEventTriggered("Switch") then
			data.state = States.Idle
			entity.ProjectileCooldown = math.random(Settings.Cooldown[1], Settings.Cooldown[2])
		end


	-- Burst / Homing shots
	elseif data.state == States.Attack2 then
		entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
		if not sprite:IsPlaying("BurstAttack") then
			sprite:Play("BurstAttack", true)
		end

		if sprite:IsEventTriggered("Shoot") then
			entity:PlaySound(SoundEffect.SOUND_BLOODSHOOT, 1.25, 0, false, 1)
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position + Vector(10, -24), Vector.Zero, entity):GetSprite().Color = entity.SplatColor
			entity.I2 = entity.I2 + 1

			local params = ProjectileParams()
			if entity.SubType == 0 then
				params.BulletFlags = (ProjectileFlags.DECELERATE | ProjectileFlags.BURST8)
				params.Scale = 2
				params.Acceleration = 1.06
				params.FallingAccelModifier = -0.175
				entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * (Settings.ShotSpeed + entity.I1), 0, params)

			elseif entity.SubType == 1 then
				params.BulletFlags = ProjectileFlags.SMART
				params.Scale = 1.5
				entity:FireProjectiles(entity.Position, Vector(Settings.BlackShotSpeed, 0), 5 + entity.I2, params)
			
			elseif FiendFolio and entity.SubType == 2 then
				params.Color = FiendFolio.ColorLemonYellow
				params.FallingAccelModifier = 0.075
				params.Scale = 1.5
				entity:FireBossProjectiles(12, target.Position, 8, params)
			end

		elseif sprite:IsEventTriggered("Switch") and (entity.I1 == 0 or (entity.I1 == 1 and entity.I2 >= Settings.Phase2Shots)) then
			data.state = States.Idle
			entity.ProjectileCooldown = math.random(Settings.Cooldown[1], Settings.Cooldown[2])
			entity.I2 = 0
		end
	end

	-- Transition to 2nd phase
	if entity.HitPoints <= entity.MaxHitPoints / 2 and entity.I1 ~= 1 then
		entity.I1 = 1
		if entity.Child then
			entity.Child:ToNPC().I1 = 1
			entity.Child:GetData().state = States.Transition
		end
	end

	-- Black champion laser
	if entity.SubType == 1 and entity.FrameCount >= 20 and entity.Child then
		local startPos = entity.Position + Vector(0, Settings.BlackLaserOffset)
		local endPos = entity.Child.Position + Vector(0, Settings.BlackLaserOffset)

		if not data.laser then
			local laser_ent_pair = {laser = EntityLaser.ShootAngle(2, entity.Position, ((entity.Child.Position - entity.Position):GetAngleDegrees()), 0, Vector(0, Settings.BlackLaserOffset), entity), entity.Child}
			data.laser = laser_ent_pair.laser

			data.laser:SetMaxDistance(startPos:Distance(endPos))
			data.laser.CollisionDamage = 0
			data.laser.Mass = 0
			data.laser:SetColor(effectColor, 0, 1, false, false)
			data.laser.DepthOffset = -200

		else
			data.laser.Angle = (endPos - startPos):GetAngleDegrees()
			data.laser:SetMaxDistance(startPos:Distance(endPos))
		end
	end


	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.heartInfamyUpdate, EntityType.ENTITY_HEART_OF_INFAMY)

function mod:kidneyBulletsFuckYouFF(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_HEART_OF_INFAMY and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 2 then
		projectile:GetData().customSpawn = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, mod.kidneyBulletsFuckYouFF, ProjectileVariant.PROJECTILE_NORMAL)