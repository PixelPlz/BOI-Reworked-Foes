local mod = ReworkedFoes

local Settings = {
	Cooldown = 60,

	-- Roll
	RollTime = 210,
	RollSpeed = 11,

	-- Jumping
	Gravity = 1,
	JumpStrength = 9,
	LandHeight = 8,
	JumpSpeed = 14, -- For big jump

	-- Sky laser
	SkyLaserDuration = 140,

	-- Corpse
	CreepTime = 90,
	CorpseBounces = 2, -- Including the final one
}



function mod:SisterVisInit(entity)
	entity.ProjectileCooldown = Settings.Cooldown / 2

	if entity.SpawnerEntity then
		entity.GroupIdx = 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.SisterVisInit, EntityType.ENTITY_SISTERS_VIS)

function mod:SisterVisUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local data = entity:GetData()
	local room = Game():GetRoom()


	-- Get the sibling
	local sibling, siblingSprite
	local isSiblingDead = false

	if entity.Child and entity.Child:Exists() then
		sibling = entity.Child:ToNPC()
		siblingSprite = sibling:GetSprite()

		-- Is sibling dead
		if sibling:GetData().corpse then
			isSiblingDead = true

		-- Share target with sibling
		elseif entity.GroupIdx == 1 then
			target = sibling:GetPlayerTarget()
		end
	end


	-- Reset variables
	local function resetVariables(sis)
		sis.ProjectileCooldown = Settings.Cooldown
		sis.I1 = 0
		sis.I2 = 0
		sis.StateFrame = 0
	end



	--[[ Alive and well ]]--
	if not data.corpse then
		-- Idle
		if entity.State == NpcState.STATE_IDLE then
			entity.Velocity = mod:StopLerp(entity.Velocity)
			mod:LoopingAnim(sprite, "Idle")

			if entity.ProjectileCooldown <= 0 and (not sibling or sibling.State == NpcState.STATE_IDLE) then
				-- Reset variables
				resetVariables(entity)

				local attackCount = 3
				-- Don't do the jump attack if the sibling doesn't exist or they're too far away
				if not sibling or not sibling:Exists() or entity.Position:Distance(sibling.Position) > 320 then
					attackCount = 2
				end
				local attack = mod:Random(1, attackCount)
				--attack = 3

				-- Roll
				if attack == 1 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("RollStart", true)

				-- Laser
				elseif attack == 2 then
					-- Sky laser
					if isSiblingDead then
						entity.State = NpcState.STATE_ATTACK3
						sprite:Play("LaserStartDown", true)
					-- Move to position for double laser
					else
						entity.State = NpcState.STATE_MOVE
					end

				-- Jump
				elseif attack == 3 then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("JumpSmall", true)
				end

				-- Do the attack with the sibling
				if sibling and isSiblingDead == false then
					resetVariables(sibling)
					sibling.State = entity.State
					siblingSprite:Play(sprite:GetAnimation(), true)

					if attack == 3 then
						sibling.StateFrame = 10
					end
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Rollin'
		elseif entity.State == NpcState.STATE_ATTACK then
			-- Start rolling
			if entity.StateFrame == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.StateFrame = 1
					entity.I1 = Settings.RollTime
					entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

					-- Get direction
					local vector = (target.Position - entity.Position):Normalized()

					-- Random if confused
					if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
						vector = mod:RandomVector()

					-- Away from target if feared or is the second sibling
					elseif (entity.GroupIdx >= 1 and isSiblingDead == false) or entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
						vector = -vector

					-- At the sibling's corpse if it exists
					elseif isSiblingDead == true then
						vector = (entity.Child.Position - entity.Position):Normalized()
					end

					entity.Velocity = vector
				end

			-- Rollin' around
			elseif entity.StateFrame == 1 then
				entity.Velocity = mod:Lerp(entity.Velocity, entity.Velocity:Resized(Settings.RollSpeed), 0.3)

				mod:LoopingAnim(sprite, "RollLoop")
				sprite.PlaybackSpeed = entity.Velocity:Length() * 0.11
				mod:FlipTowardsMovement(entity, sprite)

				-- Bounce off of obstacles
				if entity:CollidesWithGrid() then
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)
					Game():ShakeScreen(math.floor(entity.Scale * 4))
				end

				if entity.I1 == Settings.RollTime then
					sprite:SetFrame(6)
				end
				-- Stop
				if entity.I1 <= 0 then
					entity.StateFrame = 2
					sprite:Play("Taunt", true)
					sprite.PlaybackSpeed = 1
					entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

				else
					entity.I1 = entity.I1 - 1
				end

			-- Stop rolling
			elseif entity.StateFrame == 2 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end


		-- Move to position for double laser
		elseif entity.State == NpcState.STATE_MOVE then
			-- Get position
			if entity.StateFrame == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)
				mod:LoopingAnim(sprite, "Idle")


				-- Get left and right positions
				local _, posLeft =  room:CheckLine(target.Position, target.Position - Vector(1000, 0), 2, 500, false, false)
				local _, posRight = room:CheckLine(target.Position, target.Position + Vector(1000, 0), 2, 500, false, false)

				-- Get the closest side
				if not sibling or entity.Position:Distance(posLeft) < sibling.Position:Distance(posLeft) then
					entity.TargetPosition = posLeft
					entity.I1 = -1
				else
					entity.TargetPosition = posRight
					entity.I1 = 1
				end

				entity.TargetPosition = room:FindFreePickupSpawnPosition(entity.TargetPosition, 0, true, false)
				entity.TargetPosition = room:GetClampedPosition(entity.TargetPosition, 40)


				local distance = entity.Position:Distance(entity.TargetPosition)

				-- Big jump to position
				if distance > 200 then
					entity.StateFrame = 10
					sprite:Play("Jumping", true)

				-- Small jump to position
				elseif distance > 30 then
					entity.StateFrame = 1
					sprite:Play("JumpSmall", true)

				-- Already near the position
				else
					entity.State = NpcState.STATE_ATTACK2
					entity.StateFrame = 0
				end


			-- Small jump
			elseif entity.StateFrame == 1 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.StateFrame = 2
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					entity.V2 = Vector(0, Settings.JumpStrength)

					sprite.FlipX = entity.I1 == 1

					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS)
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8)
				end

			-- Jumping
			elseif entity.StateFrame == 2 then
				-- Update height
				entity.V2 = Vector(0, entity.V2.Y - Settings.Gravity)
				entity.PositionOffset = Vector(0, math.min(Settings.LandHeight, entity.PositionOffset.Y - entity.V2.Y))

				mod:LoopingAnim(sprite, "Midair")

				-- Land
				if entity.Position:Distance(entity.TargetPosition) < 20 then
					entity.Velocity = mod:StopLerp(entity.Velocity)

					if entity.PositionOffset.Y >= Settings.LandHeight then
						entity.StateFrame = 20
						sprite:Play("Land", true)
						entity.PositionOffset = Vector.Zero

						-- Destroy rocks they land on
						for i = -1, 1 do
							for j = -1, 1 do
								local gridPos = entity.Position + Vector(i * 30, j * 30)
								room:DestroyGrid(room:GetGridIndex(gridPos), true)
							end
						end
					end

				-- Move to position
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(entity.TargetPosition:Distance(entity.Position) / 5), 0.25)
				end


			-- Big jump
			elseif entity.StateFrame == 10 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Jump") then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				end

				if sprite:IsFinished() then
					entity.StateFrame = 11
				end

			-- Jumping
			elseif entity.StateFrame == 11 then
				mod:LoopingAnim(sprite, "JumpLoop")

				-- Land
				if entity.Position:Distance(entity.TargetPosition) < 20 then
					entity.StateFrame = 20
					sprite:Play("Landing", true)
					sprite.FlipX = entity.I1 == 1

				-- Move to position
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(Settings.JumpSpeed), 0.25)
				end


			-- Landed
			elseif entity.StateFrame == 20 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Land") then
					entity.Velocity = Vector.Zero
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

					-- Effects
					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.8)
					mod:PlaySound(nil, SoundEffect.SOUND_GOOATTACH0, 1.1)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_ATTACK2
					entity.StateFrame = 0
				end
			end


		-- Laser
		elseif entity.State == NpcState.STATE_ATTACK2 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Wait for sibling to get in position
			if entity.StateFrame == 0 then
				mod:LoopingAnim(sprite, "Idle")

				if not sibling or isSiblingDead == true or (sibling.State == entity.State and sibling.StateFrame >= entity.StateFrame) then
					entity.StateFrame = 1
					sprite:Play("LaserStartSide", true)
					sprite.FlipX = entity.I1 == 1
				end

			-- Start
			elseif entity.StateFrame == 1 then
				if sprite:IsFinished() then
					entity.StateFrame = 2

					local angle = 90 + entity.I1 * 90
					local offset = Vector.FromAngle(angle):Resized(20) + Vector(0, -30)

					local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.GIANT_RED, entity.Position, angle, 30, offset, entity), entity}
					data.brim = laser_ent_pair.laser
					data.brim.DepthOffset = entity.DepthOffset - 10
				end

			-- Loop
			elseif entity.StateFrame == 2 then
				mod:LoopingAnim(sprite, "LaserLoopSide")

				-- Stop
				if not data.brim:Exists() then
					entity.StateFrame = 3
					sprite:Play("LaserEndSide", true)

				else
					-- If they collide
					if sibling and sibling:GetData().brim -- Sibling's laser exists
					and entity.Position.Y <= sibling.Position.Y + 100 and entity.Position.Y >= sibling.Position.Y - 100 then -- They're close enough vertically
						local pos = entity.Position + data.brim.PositionOffset * 4 -- No clue why multiplying it by 4 makes it work
						local siblingPos = sibling.Position + sibling:GetData().brim.PositionOffset * 4
						data.brim:SetMaxDistance(pos:Distance(siblingPos) / 2)

					else
						data.brim:SetMaxDistance(0)
					end
				end

			-- Stop
			elseif entity.StateFrame == 3 then
				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end


		-- Sky Laser
		elseif entity.State == NpcState.STATE_ATTACK3 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Start
			if entity.StateFrame == 0 then
				if sprite:IsFinished() then
					entity.StateFrame = 1
					entity.I1 = Settings.SkyLaserDuration

					-- Big fuck you laser
					local pos = entity.Position + (target.Position - entity.Position):Rotated(mod:RandomSign() * 90):Resized(100)
					data.laser = Isaac.Spawn(mod.Entities.Type, mod.Entities.SkyLaser, 0, pos, Vector.Zero, entity)
					data.laser.Parent = entity

					-- Going up visual
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.SkyLaserEffect, 0, entity.Position, Vector.Zero, entity):ToEffect()
					effect:FollowParent(entity)
					effect.DepthOffset = entity.DepthOffset + 10

					data.laser.Child = effect
				end

			-- Loop
			elseif entity.StateFrame == 1 then
				mod:LoopingAnim(sprite, "LaserLoopDown")

				-- Stop
				if entity.I1 <= 0 then
					entity.StateFrame = 2
					sprite:Play("LaserEndDown", true)
					mod:FlipTowardsTarget(entity, sprite)
					data.laser.Parent = nil

				else
					entity.I1 = entity.I1 - 1
				end

			-- Stop
			elseif entity.StateFrame == 2 then
				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end


		-- Jump attack
		elseif entity.State == NpcState.STATE_JUMP then
			-- Jump
			if entity.StateFrame == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.StateFrame = 1
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					--entity.V2 = Vector(0, Settings.JumpStrength)
					entity.V2 = Vector(0, Settings.JumpStrength + entity.Position:Distance(sibling.Position) / 40)

					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS)
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8)
				end

			-- Jumping
			elseif entity.StateFrame == 1 then
				-- Update height
				entity.V2 = Vector(0, entity.V2.Y - Settings.Gravity)
				entity.PositionOffset = Vector(0, math.min(Settings.LandHeight, entity.PositionOffset.Y - entity.V2.Y))

				mod:LoopingAnim(sprite, "Midair")
				mod:FlipTowardsMovement(entity, sprite)

				-- Land
				if entity.Position:Distance(sibling.Position) < 20 then
					entity.Velocity = mod:StopLerp(entity.Velocity)

					if entity.PositionOffset.Y >= Settings.LandHeight - 20 then
						entity.StateFrame = 2
						sprite:Play("Top", true)
						entity.Position = sibling.Position
						entity.Velocity = Vector.Zero
						entity.PositionOffset = Vector.Zero

						-- Sibling
						sibling.State = entity.State
						sibling.StateFrame = 11

						if isSiblingDead == true then
							siblingSprite:Play("6feetUnder", true)
							sibling.V1 = Vector(mod:Random(359), 0)

						else
							siblingSprite:Play("Bottom", true)
						end
					end

				-- Move to position
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (sibling.Position - entity.Position):Resized(sibling.Position:Distance(entity.Position) / 8), 0.25)
				end

			-- Landed on sibling
			elseif entity.StateFrame == 2 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Jump") then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_STOMP
					entity.StateFrame = 0
					entity.TargetPosition = target.Position
				end


			-- Waiting for sibling
			elseif entity.StateFrame == 10 then
				entity.Velocity = mod:StopLerp(entity.Velocity)
				mod:LoopingAnim(sprite, "Idle")

			-- Launch the sibling
			elseif entity.StateFrame == 11 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.StateFrame = 10
				end
			end


		-- Big jump
		elseif entity.State == NpcState.STATE_STOMP then
			-- Moving to position
			if entity.StateFrame == 0 then
				mod:LoopingAnim(sprite, "JumpLoop")

				-- Land
				if entity.Position:Distance(entity.TargetPosition) < 20 then
					entity.StateFrame = 1
					sprite:Play("Landing", true)
					mod:FlipTowardsMovement(entity, sprite)

				-- Move to position
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(Settings.JumpSpeed), 0.25)
				end

			-- Landed
			elseif entity.StateFrame == 1 then
				if sprite:WasEventTriggered("Land") then
					entity.Velocity = Vector.Zero
				else
					entity.Velocity = mod:StopLerp(entity.Velocity)
				end

				if sprite:IsEventTriggered("Land") then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

					-- Projectiles
					local params = ProjectileParams()
					params.BulletFlags = entity.GroupIdx == 1 and ProjectileFlags.CURVE_RIGHT or ProjectileFlags.CURVE_LEFT
					params.BulletFlags = params.BulletFlags + ProjectileFlags.NO_WALL_COLLIDE
					entity:FireProjectiles(entity.Position, Vector(11, 10), 9, params)

					-- Shockwave
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SHOCKWAVE, 0, entity.Position, Vector.Zero, entity)

					-- Effects
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity)
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.1)
					mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1.1)
					Game():ShakeScreen(12)
					Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
					sibling.State = NpcState.STATE_IDLE
				end
			end
		end



	--[[ Corpse moding ]]--
	else
		-- Fake death
		if entity.State == NpcState.STATE_SPECIAL then
			entity.Velocity = Vector.Zero

			if sprite:IsEventTriggered("BloodStop") then
				entity.State = NpcState.STATE_IDLE
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity)
				mod:PlaySound(nil, SoundEffect.SOUND_MEAT_FEET_SLOW0)
			end


		-- Chillin'
		elseif entity.State == NpcState.STATE_IDLE then
			entity.Velocity = mod:StopLerp(entity.Velocity)
			mod:LoopingAnim(sprite, "RollLoop")
			sprite:SetFrame(4)


		-- Rollin'
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = mod:Lerp(entity.Velocity, entity.Velocity:Resized(Settings.RollSpeed), 0.3)
			mod:LoopingAnim(sprite, "RollLoop")
			sprite.PlaybackSpeed = entity.Velocity:Length() * 0.11

			-- Bounce off of obstacles
			if entity:CollidesWithGrid() then
				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)
				Game():ShakeScreen(math.floor(entity.Scale * 4))

				-- Stop
				if entity.I1 >= Settings.CorpseBounces - 1 then
					entity.State = NpcState.STATE_STOMP
					sprite:Play("Landing", true)
					sprite:SetFrame(4)
					sprite.PlaybackSpeed = 1

					entity.StateFrame = 0
					entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

					-- Projectiles
					local params = ProjectileParams()
					params.Scale = 1.25
					entity:FireBossProjectiles(14, Vector.Zero, 2, params)

				else
					entity.I1 = entity.I1 + 1
				end
			end


		-- Splattered on the wall
		elseif entity.State == NpcState.STATE_STOMP then
			if sprite:GetFrame() == 9 then
				entity.State = NpcState.STATE_IDLE
			end


		-- Jump attack
		elseif entity.State == NpcState.STATE_JUMP then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Waiting for sibling
			if entity.StateFrame == 10 then
				mod:LoopingAnim(sprite, "RollLoop")
				sprite:SetFrame(4)

			-- Launch the sibling
			elseif entity.StateFrame == 11 then
				-- Projectiles
				if not sprite:WasEventTriggered("Jump") then
					if entity.I1 <= 0 then
						local params = ProjectileParams()
						params.Scale = 1 + mod:Random(10, 80) / 100

						local angle = entity.V1.X + entity.I2 * 666
						entity:FireProjectiles(entity.Position, Vector.FromAngle(angle):Resized(mod:Random(6, 12)), 0, params)
						entity:FireProjectiles(entity.Position, Vector.FromAngle(angle + 69):Resized(mod:Random(5, 10)), 0, params)

						entity.I2 = entity.I2 + 1
						entity.I1 = 2

					else
						entity.I1 = entity.I1 - 1
					end
				end

				if sprite:IsFinished() then
					entity.StateFrame = 10
				end
			end
		end


		-- Creep
		if entity.State ~= NpcState.STATE_SPECIAL and entity:IsFrame(3, 0) then
			mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position + mod:RandomVector(mod:Random(30)), 2, Settings.CreepTime)
		end


		-- Die for real -- TODO: make them not die if there are alive sisters in the room that arent its sibling
		if not sibling then
			entity:Kill()
			entity.State = NpcState.STATE_UNIQUE_DEATH
			sprite:Play("Death", true)
			sprite:SetFrame(45)
		end
	end


	-- Cancel death for the first sister and turn into a corpse
	if entity:HasMortalDamage() and not data.corpse
	and sibling and isSiblingDead == false then
		entity.State = NpcState.STATE_SPECIAL
		sprite:Play("Death", true)
		sprite.PlaybackSpeed = 1

		entity.HitPoints = 1000
		entity.MaxHitPoints = 0
		data.corpse = true

		resetVariables(entity)
		entity:AddEntityFlags(EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_BOSSDEATH_TRIGGERED | EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

		-- Get rid of the laser
		if data.brim then
			data.brim:SetTimeout(1)
			data.brim = nil
		end

	elseif entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.SisterVisUpdate, EntityType.ENTITY_SISTERS_VIS)

function mod:SisterVisCollision(entity, target, bool)
	if target.Type == entity.Type or target.Type == EntityType.ENTITY_CAGE then
		local data = entity:GetData()
		local target = target:ToNPC()

		-- Alive
		if entity.State == NpcState.STATE_ATTACK and entity.StateFrame == 1 then
			entity.Velocity = (entity.Position - target.Position):Normalized()
			mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)

			-- Reset bounce count
			if data.corpse then
				entity.I1 = 0
			end


		-- Dead
		elseif entity.State == NpcState.STATE_IDLE and data.corpse -- Idle
		and ((target.Type == entity.Type and target.State == NpcState.STATE_ATTACK and target.StateFrame == 1) -- Hit by a sister
		or (target.Type == EntityType.ENTITY_CAGE and target.State == NpcState.STATE_ATTACK and target.I1 == 1)) then -- Hit by the Cage
			entity.State = NpcState.STATE_ATTACK
			entity.Velocity = (entity.Position - target.Position):Normalized():Rotated(mod:Random(-10, 10))
			entity.I1 = 0
			entity.StateFrame = 1
			entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.SisterVisCollision, EntityType.ENTITY_SISTERS_VIS)

function mod:SisterVisDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if (damageFlags & DamageFlag.DAMAGE_CRUSH > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.SisterVisDMG, EntityType.ENTITY_SISTERS_VIS)



--[[ Sky Laser ]]--
function mod:SisterVisSkyLaserInit(entity)
	if entity.Variant == mod.Entities.SkyLaser then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)

		entity.State = NpcState.STATE_MOVE
		entity:GetSprite():Play("StartDown", true)

		-- Effects
		mod:PlaySound(entity, SoundEffect.SOUND_MEGA_BLAST_START)

		local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity):GetSprite()
		effect.Scale = Vector(1.25, 1.25)
		effect.Color = mod.Colors.BrimShot
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.SisterVisSkyLaserInit, mod.Entities.Type)

function mod:SisterVisSkyLaserUpdate(entity)
	if entity.Variant == mod.Entities.SkyLaser then
		local sprite = entity:GetSprite()

		if entity.State == NpcState.STATE_MOVE then
			-- Stop if the parent is dead
			if not entity.Parent or not entity.Parent:Exists() or entity.Parent:HasMortalDamage() then
				entity.State = NpcState.STATE_SUICIDE
				sprite:Play("EndDown", true)
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

				-- Stop the effect too
				if entity.Child then
					entity.Child:ToEffect().State = 1
					entity.Child:GetSprite():Play("EndUp", true)
				end

				-- Sounds
				mod:PlaySound(entity, SoundEffect.SOUND_MEGA_BLAST_END)
				SFXManager():StopLoopingSounds()


			-- Move towards parent's target
			else
				local target = entity.Parent:ToNPC():GetPlayerTarget()
				entity.Velocity = mod:Lerp(entity.Velocity, (target.Position - entity.Position):Resized(12), 0.04)

				if not sprite:IsPlaying("StartDown") then
					mod:LoopingAnim(sprite, "LoopDown")
				end


				-- Effects
				Game():ShakeScreen(3)

				if Game():GetRoom():IsPositionInRoom(entity.Position, 0) then
					-- Creep
					if entity:IsFrame(3, 0) then
						mod:QuickCreep(EffectVariant.CREEP_RED, entity.Parent, entity.Position, 2, Settings.CreepTime)
					end

					-- Droplets
					if entity:IsFrame(6, 0) then
						local vector = mod:RandomVector()
						local pos = entity.Position + vector:Resized(entity.Size)
						local speed = vector:Resized(mod:Random(4, 8))
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_DROP, 0, pos, speed, entity).PositionOffset = Vector(0, -10)
					end
				end

				-- Sound
				if not SFXManager():IsPlaying(mod.Sounds.GiantLaserLoop) then
					mod:PlaySound(entity, mod.Sounds.GiantLaserLoop, 1, 1, 0, true)
				end
			end


		-- Disappear
		elseif entity.State == NpcState.STATE_SUICIDE then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsFinished() then
				entity:Remove()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.SisterVisSkyLaserUpdate, mod.Entities.Type)



-- Going up visual
function mod:SisterVisSkyLaserEffectInit(effect)
	effect:GetSprite():Play("StartUp")
	effect.SpriteOffset = Vector(0, -25)
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.SisterVisSkyLaserEffectInit, mod.Entities.SkyLaserEffect)

function mod:SisterVisSkyLaserEffectUpdate(effect)
	local sprite = effect:GetSprite()

	-- Loop
	if effect.State == 0 then
		if not sprite:IsPlaying("StartUp") then
			mod:LoopingAnim(sprite, "LoopUp")
		end

	-- End
	elseif effect.State == 1 then
		if sprite:IsFinished() then
			effect:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.SisterVisSkyLaserEffectUpdate, mod.Entities.SkyLaserEffect)