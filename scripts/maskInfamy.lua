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

	Cooldown = {80, 120},
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



function mod:maskInfamyReplace(entity)
	entity:Remove()
	Isaac.Spawn(200, 4097, entity.SubType, entity.Position, Vector.Zero, entity.SpawnerEntity):GetSprite():Play("SadMaskAppear", true)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.maskInfamyReplace, EntityType.ENTITY_MASK_OF_INFAMY)

function mod:heartInfamyReplace(entity)
	entity:Remove()
	Isaac.Spawn(200, 4098, entity.SubType, entity.Position, Vector.Zero, entity.SpawnerEntity)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.heartInfamyReplace, EntityType.ENTITY_HEART_OF_INFAMY)



function mod:maskInfamyUpdate(entity)
	if entity.Variant == 4097 or entity.Variant == 4098 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()

		if not data.state then
			data.state = States.Appear

			-- Champion sprites
			if entity.SubType == 1 then
				for i = 0, sprite:GetLayerCount() do
					sprite:ReplaceSpritesheet(i, "gfx/bosses/classic/boss_057_maskofinfamy_black.png")
				end
				sprite:LoadGraphics()
				entity.SplatColor = effectColor
				
				if entity.Variant == 4097 then
					entity:ToNPC().Scale = 1.15
				end
			end
		end


		-- Mask
		if entity.Variant == 4097 then
			if data.state == States.Appear then
				data.state = States.Idle
				entity.Velocity = Vector.Zero
				entity.I1 = 0
				entity.ProjectileCooldown = Settings.ChargeCooldown / 2
				data.place = Isaac:GetRandomPosition()
				entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_NO_STATUS_EFFECTS)

				-- Get corresponding heart
				if not entity.Child then
					local foundHeart = false
					for _,v in pairs(Isaac.GetRoomEntities()) do
						if v.Type == 200 and v.Variant == 4098 and not v.Parent then
							v.Parent = entity
							entity.Child = v
							foundHeart = true
							break
						end
					end
					
					if foundHeart == false then
						entity.Position = entity.Position - Vector(20, 0)
						local heart = Isaac.Spawn(200, 4098, entity.SubType, entity.Position + Vector(40, 0), Vector.Zero, entity)
						heart.Parent = entity
						entity.Child = heart
					end
				end


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
			if not entity.Child or entity.Child:IsDead() then
				entity:Kill()
			end


		-- Heart
		elseif entity.Variant == 4098 then
			if data.state == States.Appear then
				data.state = States.Idle
				entity.Velocity = Vector.Zero
				entity.ProjectileCooldown = Settings.Cooldown[1]
				entity.I1 = 0

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
				if sprite:IsEventTriggered("Shoot") then
					entity:PlaySound(SoundEffect.SOUND_HEARTBEAT_FASTEST, 1.15, 0, false, 1)
				end

				-- Decide attack
				if entity.ProjectileCooldown <= 0 then
					local whichAttack = math.random(1, 2)
					if entity.SubType == 1 and (entity.Parent or entity.I1 == 0) then
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
					if entity.I1 == 0 or entity.SubType == 1 then
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
					local params = ProjectileParams()
					params.CircleAngle = 0.41
					params.Scale = 1.5
					entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed - 5, 8), 9, params)

					params.Scale = 1.25
					entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 0), 8, params)

					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity).SpriteScale = Vector(0.75, 0.75)
					SFXManager():Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.75 + (entity.I1 * 0.25))
					
					-- Creep for jump attack
					if sprite:IsPlaying("HeartAttackAlt") then
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position, Vector.Zero, entity):ToEffect().Scale = 1.5
						for i = 0, 8 do
							Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position + (Vector.FromAngle(i * 45) * 40), Vector.Zero, entity):ToEffect().Scale = 1.5
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
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position + Vector(8, -24), Vector.Zero, entity)
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
						effect:GetSprite().Color = effectColor
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
				if entity.Parent then
					entity.Parent:ToNPC().I1 = 1
					entity.Parent:GetData().state = States.Transition
				end
			end

			-- Black champion laser
			if entity.SubType == 1 and entity.FrameCount >= 20 and entity.Parent then
				local startPos = entity.Position + Vector(0, Settings.BlackLaserOffset)
				local endPos = entity.Parent.Position + Vector(0, Settings.BlackLaserOffset)

				if not data.laser then
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(2, entity.Position, ((entity.Parent.Position - entity.Position):GetAngleDegrees()), 0, Vector(0, Settings.BlackLaserOffset), entity), entity.Parent}
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
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.maskInfamyUpdate, 200)

function mod:maskInfamyDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 4097 then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.maskInfamyDMG, 200)

function mod:maskInfamyCollide(entity, target, bool)
	if entity.Variant == 4097 and target.Type == 200 and target.Variant == 4098 then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.maskInfamyCollide, 200)