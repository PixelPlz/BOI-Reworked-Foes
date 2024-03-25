local mod = ReworkedFoes

local Settings = {
	NewHealth = 520,
	BlackLaserOffset = -35,

	-- Mask
	MoveSpeed = 4,
	DamageIncrease = 20, -- When hit in the back
	ChargeCooldown = 20,

	SideRange = 40,
	FrontRange = 400,
	ChargeSpeed = 10,
	AngrySpeed = 54,

	MinChargeTime = 18,
	StunTime = 25,

	-- Heart
	WanderSpeed = 2,
	RunSpeed = 5,
	Cooldown = 60,
}



--[[ Mask ]]--
function mod:MaskInfamyInit(entity)
	entity.ProjectileCooldown = Settings.ChargeCooldown
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_NO_STATUS_EFFECTS)

	-- Black champion
	if entity.SubType == 1 then
		entity.SplatColor = mod.Colors.RagManBlood

	-- Yellow champion
	elseif entity.SubType == 2 then
		entity.SplatColor = FiendFolio.ColorLemonYellow
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MaskInfamyInit, EntityType.ENTITY_MASK_OF_INFAMY)

function mod:MaskInfamyUpdate(entity)
	local sprite = entity:GetSprite()
	local facingAngle = entity.Velocity:GetAngleDegrees()


	-- Play the correct animation when moving
	local function playDirectionalAnimation()
		local prefix = entity.I1 == 1 and "Angry" or "Sad"
		mod:LoopingAnim(sprite, prefix .. "Mask" .. mod:GetDirectionString(facingAngle))
	end


	-- Schmovin'
	if entity.State == NpcState.STATE_MOVE then
		-- Movement
		-- Stay near the heart (for non-champion 2nd phase and black champion)
		if entity.SubType ~= 2 and (entity.SubType == 1 or entity.I1 == 1) then
			if entity.Position:Distance(entity.TargetPosition) <= 40 or not entity.Pathfinder:HasPathToPos(entity.TargetPosition) -- At position or there is no path to it
			or entity.TargetPosition:Distance(entity.Parent.Position) > 280 then -- Position is too far from parent
				entity.TargetPosition = entity.Parent.Position + mod:RandomVector(mod:Random(60, 160))
				entity.TargetPosition = Game():GetRoom():FindFreePickupSpawnPosition(entity.TargetPosition, 0, false, false)
			end

			entity.Pathfinder:FindGridPath(entity.TargetPosition, Settings.MoveSpeed / 6, 500, false)

		-- Roam around randomly
		else
			mod:MoveRandomGridAligned(entity, Settings.MoveSpeed, false, true)
		end

		playDirectionalAnimation()

		if entity.ProjectileCooldown <= 0 then
			local chargeCheck = mod:CheckCardinalAlignment(entity, Settings.SideRange, Settings.FrontRange, 3, 2, facingAngle)

			-- Charge if in range
			if chargeCheck ~= false then
				entity.State = NpcState.STATE_ATTACK
				entity.V1 = Vector.FromAngle(chargeCheck)
				entity.Velocity = entity.V1
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8 + entity.I1 * 0.2, 1.02)
			end

		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end


	-- Charging
	elseif entity.State == NpcState.STATE_ATTACK then
		-- Movement
		-- 2nd phase
		if entity.I1 == 1 then
			entity.Velocity = mod:Lerp(entity.Velocity, entity.V1:Resized(Settings.AngrySpeed), 0.015)
			entity.I2 = entity.I2 + 1 -- Only crash if it charged for long enough

		-- 1st phase
		else
			entity.Velocity = mod:Lerp(entity.Velocity, entity.V1:Resized(Settings.ChargeSpeed), 0.25)
		end

		-- Yellow champion creep
		if entity.SubType == 2 and entity:IsFrame(2, 0) then
			mod:QuickCreep(EffectVariant.CREEP_YELLOW, entity, entity.Position, 1.25)
		end


		if entity:CollidesWithGrid() then
			-- 2nd phase, charged for long enough
			if entity.I1 == 1 and entity.I2 >= Settings.MinChargeTime then
				entity.State = NpcState.STATE_IDLE
				entity.I2 = Settings.StunTime

				-- Projectiles
				if entity.SubType == 0 and entity.I1 == 1 then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_ROCK
					entity:FireBossProjectiles(12, entity.Position + -entity.V1:Resized(10), 2, params)
				end

				-- Effects
				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.OneTimeEffect, 0, entity.Position, Vector.Zero, entity):GetSprite()
				effect:Load("gfx/1000.016_poof02_c.anm2", true)
				effect:Play("Poof", true)

				effect.Color = mod.Colors.DustPoof
				effect.Scale = Vector(1.2, 1.2)

				effect.Rotation = entity.V1:GetAngleDegrees() - 90
				effect.Offset = -entity.V1:Resized(8) + Vector(0, -28)

				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS)
				mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND)
				Game():ShakeScreen(12)


			-- 1st phase / 2nd phase didn't charge for long enough
			else
				entity.State = NpcState.STATE_MOVE
				entity.Velocity = -entity.V1
				entity.I2 = 0
				entity.ProjectileCooldown = Settings.ChargeCooldown
			end

		-- Update animation
		else
			playDirectionalAnimation()
		end

	-- Stunned
	elseif entity.State == NpcState.STATE_IDLE then
		entity.Velocity = mod:StopLerp(entity.Velocity, 0.15)

		if entity.I2 <= 0 then
			entity.State = NpcState.STATE_MOVE
			entity.ProjectileCooldown = Settings.ChargeCooldown

		else
			-- Dumb bullshit to fix his back hitbox not being in the sprite's back
			if entity.I2 == Settings.StunTime - 5 then
				entity.Velocity = entity.V1:Resized(0.01)
			end
			entity.I2 = entity.I2 - 1
		end


	-- Transition
	elseif entity.State == NpcState.STATE_SPECIAL then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsEventTriggered("Sound") then
			entity.I1 = 1

			-- Effects
			for i = 0, 5 do
				local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 6, entity.Position, mod:RandomVector(3), entity):ToEffect()
				rocks:GetSprite():Play("rubble", true)
				rocks.State = 2
			end

			mod:PlaySound(nil, SoundEffect.SOUND_ROCK_CRUMBLE, 0.9, 1.02)
			mod:PlaySound(entity, SoundEffect.SOUND_MOUTH_FULL)
		end

		if sprite:IsFinished() then
			entity.State = NpcState.STATE_MOVE
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
	if entity:ToNPC().I1 == 1 and entity.Parent and damageSource.Type ~= EntityType.ENTITY_HEART_OF_INFAMY then
		local onePercent = damageAmount / 100
		local increase = onePercent * Settings.DamageIncrease

		entity.Parent:TakeDamage(damageAmount + increase, damageFlags + DamageFlag.DAMAGE_COUNTDOWN, damageSource, 1)
		entity:SetColor(mod.Colors.DamageFlash, 2, 0, false, true)
		return false
	end
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
	entity.MaxHitPoints = Settings.NewHealth
	entity.HitPoints = entity.MaxHitPoints

	entity.ProjectileCooldown = Settings.Cooldown / 2

	-- Black champion
	if entity.SubType == 1 then
		entity.SplatColor = mod.Colors.RagManBlood

	-- Yellow champion
	elseif entity.SubType == 2 then
		entity.SplatColor = FiendFolio.ColorLemonYellow

		local sprite = entity:GetSprite()
		sprite:Load("gfx/098.000_heart of infamy.anm2", true)
		sprite:Play("HeartAppear", true)
		sprite:ReplaceSpritesheet(0, "gfx/bosses/classic/boss_057_maskofinfamy_yellow.png", true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.HeartInfamyInit, EntityType.ENTITY_HEART_OF_INFAMY)

function mod:HeartInfamyUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()


	--[[ Chillin' ]]
	if entity.State == NpcState.STATE_MOVE then
		mod:AvoidPlayer(entity, 180, Settings.WanderSpeed, Settings.RunSpeed)

		local suffix = entity.I1 == 1 and "Faster" or ""
		mod:LoopingAnim(sprite, "HeartBeat" .. suffix)


		-- Attack
		if entity.ProjectileCooldown <= 0 then
			if entity.Position:Distance(target.Position) <= 280 then
				-- Reset variables
				entity.ProjectileCooldown = Settings.Cooldown
				entity.I2 = 0
				entity.StateFrame = 0

				-- Decide attack
				local attackCount = 2

				if entity.SubType == 1 then
					attackCount = 1
				end
				if entity.I1 == 1 then
					attackCount = attackCount + 1
				end
				local attack = mod:Random(1, attackCount)

				-- Black champion doesn't do the push attack
				if entity.SubType == 1 and attack == 2 then
					attack = 3
				end


				-- Slam attack
				if attack == 1 then
					entity.State = NpcState.STATE_ATTACK
					local attackSuffix = entity.I1 == 1 and "Double" or ""
					sprite:Play("HeartAttack" .. attackSuffix, true)

				-- Push attack
				elseif attack == 2 then
					entity.State = NpcState.STATE_ATTACK2
					sprite:Play("HeartPush", true)
					mod:PlaySound(nil, SoundEffect.SOUND_HEARTIN)

				-- Squeeze attack
				elseif attack == 3 then
					entity.State = NpcState.STATE_ATTACK3
					sprite:Play("HeartSqueeze", true)
					entity.TargetPosition = mod:RandomVector()
				end
			end

		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end



	--[[ Slam attack ]]--
	elseif entity.State == NpcState.STATE_ATTACK then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsEventTriggered("Shoot") or sprite:IsEventTriggered("Shoot2") then
			-- Projectiles
			local params = ProjectileParams()

			-- Black champion
			if entity.SubType == 1 then
				params.BulletFlags = ProjectileFlags.SMART
				params.Scale = 1.25

				entity.I2 = entity.I2 + 1
				entity:FireProjectiles(entity.Position, Vector(10, 0), 5 + entity.I2, params)


			-- Yellow champion
			elseif entity.SubType == 2 then
				params.Color = FiendFolio.ColorLemonYellow

				-- 1st
				if sprite:IsEventTriggered("Shoot") then
					for i = 0, 2 do
						-- Cardinal lines
						params.Scale = 2 - (i * 0.5)
						entity:FireProjectiles(entity.Position, Vector(11 - i * 2.5, 4), 6, params)

						-- Diagonal lines
						if i >= 1 then
							entity:FireProjectiles(entity.Position, Vector(11 - i * 2.5, 4), 7, params)
						end
					end

				-- 2nd
				elseif sprite:IsEventTriggered("Shoot2") then
					params.Scale = 1.25
					entity:FireBossProjectiles(12, Vector.Zero, 2, params)
				end


			-- Regular
			else
				-- 1st
				if sprite:IsEventTriggered("Shoot") then
					params.Scale = 1.5
					entity:FireProjectiles(entity.Position, Vector(11, 0), 8, params)

				-- 2nd
				elseif sprite:IsEventTriggered("Shoot2") then
					params.Scale = 1.25
					params.CircleAngle = 0
					entity:FireProjectiles(entity.Position, Vector(10, 12), 9, params)
				end
			end


			-- Effects
			mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS)

			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity):GetSprite()
			effect.Scale = Vector(0.8, 0.8)
			effect.Color = entity.SubType == 1 and mod.Colors.RagManPurple or entity.SplatColor

			-- 2nd stomp effects
			if entity.SubType ~= 1 and sprite:IsEventTriggered("Shoot2") then
				mod:QuickCreep(entity.SubType == 2 and EffectVariant.CREEP_YELLOW or EffectVariant.CREEP_RED, entity, entity.Position, 2.5)

				local extraEffect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):GetSprite()
				extraEffect.Offset = Vector(6, entity.Scale * -18)
				extraEffect.Scale = Vector(0.8, 0.8)
				extraEffect.Color = entity.SplatColor
			end
		end

		if sprite:IsFinished() then
			entity.State = NpcState.STATE_MOVE
		end


	-- Push attack
	elseif entity.State == NpcState.STATE_ATTACK2 then
		if sprite:IsEventTriggered("Shoot") then
			entity.TargetPosition = (target.Position - entity.Position):Normalized()
			entity.Velocity = -entity.TargetPosition:Resized(16)

			-- Burst projectile for non-champion
			if entity.SubType == 0 then
				local params = ProjectileParams()
				params.BulletFlags = (ProjectileFlags.DECELERATE | ProjectileFlags.BURST8)
				params.Scale = 2
				params.Acceleration = 1.08
				params.FallingAccelModifier = -0.175
				mod:FireProjectiles(entity, entity.Position, (target.Position - entity.Position):Resized(12), 0, params, Color.Default)
			end


			-- Effects
			mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT)
			mod:ShootEffect(entity, 4, Vector(0, entity.Scale * -24), entity.SplatColor)

			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):GetSprite()
			effect.Offset = Vector(10, entity.Scale * -34)
			effect.Scale = Vector(0.8, 0.8)
			effect.Color = entity.SplatColor
		end

		if sprite:IsFinished() then
			entity.State = NpcState.STATE_MOVE
		end


		-- Pushed back
		if sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("Shoot2") then
			entity.Velocity = mod:StopLerp(entity.Velocity, 0.1)

			-- Yellow champion piss stream
			if entity.SubType == 2 and entity:IsFrame(entity.I2 % 2 + 1, 0) then
				local params = ProjectileParams()
				params.Color = FiendFolio.ColorLemonYellow
				params.Scale = 1 + (entity.I2 / 20) + (mod:Random(50) / 100)

				params.FallingAccelModifier = mod:Random(100, 125) / 100
				params.FallingSpeedModifier = mod:Random(-16, -10) + entity.I2 / 2

				local vector = entity.TargetPosition:Rotated(mod:Random(-12, 12))
				entity:FireProjectiles(entity.Position, vector:Resized(11 - entity.I2 * 0.5), 0, params)

				entity.I2 = entity.I2 + 1
			end

		else
			entity.Velocity = mod:StopLerp(entity.Velocity)
		end



	--[[ Squeeze attack ]]--
	elseif entity.State == NpcState.STATE_ATTACK3 then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		-- Black champion
		if entity.SubType == 1 then
			local color = {R = 0.4, G = 0.2, B = 0.8}

			-- Charge up
			if sprite:IsEventTriggered("Shoot") then
				entity:SetColor(Color(1,1,1, 1, color.R,color.G,color.B), 10, 1, true, false)
				mod:PlaySound(nil, SoundEffect.SOUND_LASERRING_WEAK)
				entity.TargetPosition = target.Position

			-- Shoot
			elseif sprite:IsEventTriggered("Shoot2") then
				-- Homing shots from the mask
				if entity.Child then
					-- Projectiles
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_HUSH
					params.BulletFlags = ProjectileFlags.SMART
					params.Scale = 1.25
					params.CircleAngle = mod:Random(1) * mod:DegreesToRadians(30)
					entity:FireProjectiles(entity.Child.Position, Vector(10, 6), 9, params)

					-- Effects
					entity.Child:SetColor(Color(1,1,1, 1, color.R,color.G,color.B), 10, 1, true, false) -- Mask
					entity:GetData().laser:SetColor(Color(1,1,1, 1, color.R * 2,color.G * 2,color.B * 2), 10, 1, true, false) -- Laser
					mod:PlaySound(nil, SoundEffect.SOUND_REDLIGHTNING_ZAP, 1, 0.95)


				-- Laser at the player if there is no mask
				else
					-- Create laser
					local pos = mod:Lerp(entity.TargetPosition, target.Position, 0.4)
					local angle = (pos - entity.Position):GetAngleDegrees()
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(2, entity.Position, angle, 3, Vector(0, Settings.BlackLaserOffset), entity), entity}
					local laser = laser_ent_pair.laser

					-- Set up the parameters
					laser.Mass = 0
					laser.DepthOffset = entity.DepthOffset - 10
					laser.OneHit = true
					laser:SetColor(Color(0.6,0.6,0.6, 1, 0.2,0.1,0.4), 0, 1, false, false)

					-- Effects
					entity:SetColor(Color(1,1,1, 1, color.R,color.G,color.B), 10, 1, true, false)
				end
			end


		else
			if sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("Shoot2") then
				if entity.StateFrame <= 0 then
					local params = ProjectileParams()

					-- Yellow champion
					if entity.SubType == 2 then
						-- Projectiles
						params.Scale = 1 + mod:Random(10, 80) / 100
						params.Color = FiendFolio.ColorLemonYellow

						local vector = entity.TargetPosition:Rotated(entity.I2 * 666)
						entity:FireProjectiles(entity.Position, vector:Resized(mod:Random(6, 11)), 0, params)
						entity:FireProjectiles(entity.Position, vector:Rotated(69):Resized(mod:Random(5, 9)), 0, params)

						-- Creep
						local creepVector = mod:RandomVector(mod:Random(60))
						mod:QuickCreep(EffectVariant.CREEP_YELLOW, entity, entity.Position + creepVector, 2 + mod:Random(1) * 0.5)
						mod:ShootEffect(entity, 3, Vector(0, entity.Scale * -20) + creepVector:Resized(18), FiendFolio.ColorLemonYellow, 1, true)
						mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 0.8, 1, 4)


					-- Regular
					else
						params.Scale = 1 + entity.I2 * 0.25

						for i = 0, 2 do
							-- Projectiles
							local vector = entity.TargetPosition:Rotated(i * 120 + entity.I2 * 15)
							entity:FireProjectiles(entity.Position, vector:Resized(9.5), 0, params)

							-- Effects
							if entity.I2 % 2 == 0 then
								mod:ShootEffect(entity, 3, Vector(0, entity.Scale * -20) + vector:Resized(18), Color.Default, 1, true)
							end
						end
					end

					mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)
					entity.I2 = entity.I2 + 1
					entity.StateFrame = 2 + (entity.SubType == 0 and entity.I2 % 2 or 0)

				else
					entity.StateFrame = entity.StateFrame - 1
				end
			end
		end

		if sprite:IsFinished() then
			entity.State = NpcState.STATE_MOVE
		end
	end



	-- Transition to 2nd phase
	if entity.I1 ~= 1 and entity.HitPoints <= entity.MaxHitPoints / 2 then
		entity.I1 = 1

		if entity.Child then
			entity.Child:ToNPC().State = NpcState.STATE_SPECIAL
			entity.Child:GetSprite():Play("AngryMaskAppear", true)
		end
	end


	-- Black champion laser
	if entity.SubType == 1 and entity.FrameCount > 20 and entity.Child then
		local data = entity:GetData()
		local startPos = entity.Position + Vector(0, Settings.BlackLaserOffset)
		local endPos = entity.Child.Position + Vector(0, Settings.BlackLaserOffset)

		-- Create the laser
		if not data.laser then
			local angle = (entity.Child.Position - entity.Position):GetAngleDegrees()
			local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THIN_RED, entity.Position, angle, -1, Vector(0, Settings.BlackLaserOffset), entity), entity}
			data.laser = laser_ent_pair.laser

			data.laser:SetMaxDistance(startPos:Distance(endPos))
			data.laser.CollisionDamage = 0 -- This still deals damage to the player (and enemies but it's only 0.1)
			data.laser.Mass = 0
			data.laser:SetColor(Color(0.6,0.6,0.6, 1, 0.2,0.1,0.4), 0, 1, false, false)
			data.laser.DepthOffset = -200

		-- Update the laser
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