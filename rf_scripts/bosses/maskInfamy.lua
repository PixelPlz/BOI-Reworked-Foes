local mod = ReworkedFoes

local Settings = {
	-- Mask
	MoveSpeed = 4,
	ChargeSpeed = 54,
	AngrySpeed = 64,

	SideRange = 40,
	FrontRange = 320,

	ChargeCooldown = 30,
	StunTime = 20,
	CrashScreenShake = 12,
	MinChargeTime = 15,

	-- Heart
	WanderSpeed = 2,
	RunSpeed = 5,
	NewHealth = 450,
	Cooldown = 90,

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



--[[ Mask ]]--
function mod:MaskInfamyInit(entity)
	local data = entity:GetData()

	data.state = States.Appear
	entity.ProjectileCooldown = Settings.ChargeCooldown / 2
	data.place = Isaac:GetRandomPosition()
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_NO_STATUS_EFFECTS)

	if entity.SubType == 1 then
		entity.SplatColor = mod.Colors.RagManBlood
	elseif entity.SubType == 2 and FiendFolio then
		entity.SplatColor = FiendFolio.ColorLemonYellow
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MaskInfamyInit, EntityType.ENTITY_MASK_OF_INFAMY)

function mod:MaskInfamyUpdate(entity)
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
			mod:MoveRandomGridAligned(entity, Settings.MoveSpeed, false, true)
			-- Get animation direction
			data.facing = mod:GetDirectionString(entity.Velocity:GetAngleDegrees())

			-- Charge (this is horrible)
			if entity.ProjectileCooldown <= 0
			and Game():GetRoom():CheckLine(entity.Position, target.Position, 0, 0, false, false)
			and entity.Position:Distance(target.Position) <= Settings.FrontRange then
				if (entity.Position.X <= target.Position.X + Settings.SideRange and entity.Position.X >= target.Position.X - Settings.SideRange)
				or (entity.Position.Y <= target.Position.Y + Settings.SideRange and entity.Position.Y >= target.Position.Y - Settings.SideRange) then
					if not ((data.facing == "Left" and target.Position.X > entity.Position.X + Settings.SideRange)
					or (data.facing == "Right" and target.Position.X < entity.Position.X + Settings.SideRange)
					or (data.facing == "Up" and target.Position.Y > entity.Position.Y + Settings.SideRange)
					or (data.facing == "Down" and target.Position.Y < entity.Position.Y + Settings.SideRange)) then
						data.state = States.Attack1
						entity.Velocity = Vector.Zero
						mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR)

						local angle = (target.Position - entity.Position):GetAngleDegrees()
						data.facing = mod:GetDirectionString(angle)
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
			entity.Velocity = mod:Lerp(entity.Velocity, Vector.FromAngle(angle):Resized(speed), 0.015)
			entity.I2 = entity.I2 + 1 -- Only crash if it charged for long enough

			-- Crash into wall
			if entity:CollidesWithGrid() then
				if entity.I2 >= Settings.MinChargeTime then
					data.state = States.Attack2
					entity.ProjectileCooldown = Settings.StunTime + (entity.I1 * (Settings.StunTime / 2))
					mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND)
					Game():ShakeScreen(Settings.CrashScreenShake)

					-- Rock shots
					if entity.SubType == 0 or entity.I1 == 1 then
						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_ROCK
						entity:FireBossProjectiles(10 - (entity.I1 * 2), entity.Position + -Vector.FromAngle(angle):Resized(20), 1.5, params)

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

			-- Yellow champion creep
			if FiendFolio and entity.SubType == 2 and entity:IsFrame(2, 0) and entity.I2 >= 7 then
				mod:QuickCreep(EffectVariant.CREEP_YELLOW, entity, entity.Position, 1.15)
			end


		-- Stunned
		elseif data.state == States.Attack2 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if entity.ProjectileCooldown <= 0 then
				data.state = States.Idle
				entity.ProjectileCooldown = Settings.ChargeCooldown
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end
		end

		-- Animation
		mod:LoopingAnim(sprite, prefix .. "Mask" .. data.facing)


	-- Transition to 2nd phase
	elseif data.state == States.Transition then
		entity.Velocity = Vector.Zero

		if not sprite:IsPlaying("AngryMaskAppear") then
			sprite:Play("AngryMaskAppear", true)
			sprite:SetFrame(6)
			mod:PlaySound(entity, SoundEffect.SOUND_MOUTH_FULL)
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
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.MaskInfamyUpdate, EntityType.ENTITY_MASK_OF_INFAMY)

function mod:MaskInfamyDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.MaskInfamyDMG, EntityType.ENTITY_MASK_OF_INFAMY)

function mod:MaskInfamyCollision(entity, target, bool)
	if target.Type == EntityType.ENTITY_HEART_OF_INFAMY then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.MaskInfamyCollision, EntityType.ENTITY_MASK_OF_INFAMY)



--[[ Heart ]]--
function mod:HeartInfamyInit(entity)
	local data = entity:GetData()

	data.state = States.Appear
	entity.ProjectileCooldown = Settings.Cooldown / 2
	entity.MaxHitPoints = Settings.NewHealth
	entity.HitPoints = entity.MaxHitPoints

	if entity.SubType == 1 then
		entity.SplatColor = mod.Colors.RagManBlood
	elseif entity.SubType == 2 then
		entity.SplatColor = FiendFolio.ColorLemonYellow
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.HeartInfamyInit, EntityType.ENTITY_HEART_OF_INFAMY)

function mod:HeartInfamyUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()
	local target = entity:GetPlayerTarget()


	if not data.state or data.state == States.Appear then
		data.state = States.Idle
		if entity.Child then
			entity.Child.Parent = entity
		end

	elseif data.state == States.Idle then
		mod:AvoidPlayer(entity, 160, Settings.WanderSpeed, Settings.RunSpeed)

		local suffix = ""
		if entity.I1 == 1 then
			suffix = "Alt"
		end
		mod:LoopingAnim(sprite, "HeartBeat" .. suffix)


		-- Decide attack
		if entity.ProjectileCooldown <= 0 then
			local whichAttack = mod:Random(1, 2)
			if entity.SubType == 1 then
				whichAttack = 2
			end

			if whichAttack == 1 then
				data.state = States.Attack1
				sprite:Play("HeartAttack" .. suffix, true)

			elseif whichAttack == 2 then
				data.state = States.Attack2
				sprite:Play("BurstAttack", true)
			end

		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end


	-- Ground slam
	elseif data.state == States.Attack1 then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsEventTriggered("Jump") then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT)

		elseif sprite:IsEventTriggered("GetPos") then
			entity.Position = target.Position


		elseif sprite:IsEventTriggered("Shoot") then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1 + (entity.I1 * 0.25))

			if sprite:IsPlaying("HeartAttackAlt") then
				Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)
			end

			local params = ProjectileParams()
			-- FF kidney champion
			if FiendFolio and entity.SubType == 2 then
				mod:QuickCreep(EffectVariant.CREEP_YELLOW, entity, entity.Position, 3)
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
				params.CircleAngle = 0.4
				params.Scale = 1.5
				entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed - 5, 8), 9, params)

				params.Scale = 1.25
				entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 0), 8, params)

				-- Creep for jump attack
				if sprite:IsPlaying("HeartAttackAlt") then
					mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 5)
				-- Slam effect
				else
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity).SpriteScale = Vector(0.8, 0.8)
				end
			end
		end

		if sprite:IsFinished() then
			data.state = States.Idle
			entity.ProjectileCooldown = Settings.Cooldown
		end


	-- Burst / Homing shots
	elseif data.state == States.Attack2 then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsEventTriggered("Shoot") then
			mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 1.25)
			entity.I2 = entity.I2 + 1

			-- Effect
			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):ToEffect()
			effect:FollowParent(entity)
			effect.ParentOffset = Vector(12, entity.Scale * -32)

			local effectSprite = effect:GetSprite()
			effectSprite.Scale = Vector(0.8, 0.8)
			effectSprite.Color = entity.SplatColor


			local params = ProjectileParams()
			if entity.SubType == 0 then
				params.BulletFlags = (ProjectileFlags.DECELERATE | ProjectileFlags.BURST8)
				params.Scale = 2
				params.Acceleration = 1.06
				params.FallingAccelModifier = -0.175
				entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(Settings.ShotSpeed + entity.I1), 0, params)

			-- Black champion
			elseif entity.SubType == 1 then
				params.BulletFlags = ProjectileFlags.SMART
				params.Scale = 1.5
				entity:FireProjectiles(entity.Position, Vector(Settings.BlackShotSpeed, 0), 5 + entity.I2, params)

			-- FF kidney champion
			elseif FiendFolio and entity.SubType == 2 then
				params.Color = FiendFolio.ColorLemonYellow
				params.FallingAccelModifier = 0.075
				params.Scale = 1.5
				entity:FireBossProjectiles(12, target.Position, 8, params)
			end
		end

		if sprite:IsFinished() then
			-- Attack 2 times in second phase
			if entity.I1 == 1 and entity.I2 < Settings.Phase2Shots then
				sprite:Play("BurstAttack", true)
			else
				data.state = States.Idle
				entity.ProjectileCooldown = Settings.Cooldown
				entity.I2 = 0
			end
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
	if entity.SubType == 1 and entity.FrameCount > 20 and entity.Child then
		local startPos = entity.Position + Vector(0, Settings.BlackLaserOffset)
		local endPos = entity.Child.Position + Vector(0, Settings.BlackLaserOffset)

		if not data.laser then
			local angle = (entity.Child.Position - entity.Position):GetAngleDegrees()
			local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THIN_RED, entity.Position, angle, 0, Vector(0, Settings.BlackLaserOffset), entity), entity.Child}
			data.laser = laser_ent_pair.laser

			data.laser:SetMaxDistance(startPos:Distance(endPos))
			data.laser.CollisionDamage = 0
			data.laser.Mass = 0
			data.laser:SetColor(Color(0.5,0.5,0.7, 1, 0.1,0.1,0.25), 0, 1, false, false)
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
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.HeartInfamyUpdate, EntityType.ENTITY_HEART_OF_INFAMY)

-- Fiend Folio kidney champion bullets
function mod:FiendFolioKidneyBullets(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_HEART_OF_INFAMY and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 2 then
		projectile:GetData().customSpawn = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, mod.FiendFolioKidneyBullets, ProjectileVariant.PROJECTILE_NORMAL)