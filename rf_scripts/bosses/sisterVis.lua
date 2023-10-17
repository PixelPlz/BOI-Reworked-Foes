local mod = ReworkedFoes

local Settings = {
	NewHealth = 400,
	Cooldown = 60,
	DamageReduction = 20, -- If the sibling is dead and it didn't enrage yet

	-- Roll
	RollTime = 210,
	RollSpeed = 11,

	-- Jumping
	Gravity = 1,
	JumpStrength = 10,
	LandHeight = 8,
	JumpSpeed = 15, -- For big jump

	-- Sky laser
	SkyLaserDuration = 140,

	-- Corpse
	CreepTime = 90,
	CorpseBounces = 2, -- Including the final one
	CorpseJumpStrength = 15,
}



function mod:SisterVisInit(entity)
	entity.MaxHitPoints = Settings.NewHealth
	entity.HitPoints = entity.MaxHitPoints

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
		-- Target any Gishes first
		if not entity.Target and not data.wasDelirium then
			for i, gish in pairs(Isaac.FindByType(EntityType.ENTITY_MONSTRO2, 1, 0, false, false)) do
				if gish:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) ~= entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and not gish:GetData().wasDelirium then
					entity.Target = gish
					break
				end
			end
		end

		-- Get animation prefix
		local prefix = ""
		if data.enraged and data.enraged == true then
			prefix = "Angry"
		end


		-- Idle
		if entity.State == NpcState.STATE_IDLE then
			entity.Velocity = mod:StopLerp(entity.Velocity)
			mod:LoopingAnim(sprite, prefix .. "Idle")

			-- Get pissed if the sibling dies
			if sibling and isSiblingDead and not data.enraged then
				entity.State = NpcState.STATE_SPECIAL
				sprite:Play("AngryStart", true)
				mod:PlaySound(entity, SoundEffect.SOUND_GHOST_ROAR, 1, 1.02)


			-- Attack
			else
				if entity.ProjectileCooldown <= 0 and (not sibling or sibling.State == NpcState.STATE_IDLE) then
					-- Reset variables
					resetVariables(entity)

					local attackCount = 3
					-- Don't do the jump attack if the sibling doesn't exist
					if not sibling or not sibling:Exists() then
						attackCount = 2
					end
					local attack = mod:Random(1, attackCount)


					-- Roll
					if attack == 1 then
						entity.State = NpcState.STATE_ATTACK
						sprite:Play(prefix .. "RollStart", true)
						mod:PlaySound(entity, SoundEffect.SOUND_FAT_WIGGLE)

					-- Laser
					elseif attack == 2 then
						-- Sky laser
						if data.enraged then
							entity.State = NpcState.STATE_ATTACK3
							sprite:Play("AngryLaserStart", true)

						-- Move to position for double laser
						else
							entity.State = NpcState.STATE_MOVE
						end

					-- Jump
					elseif attack == 3 then
						entity.State = NpcState.STATE_JUMP
						sprite:Play(prefix .. "Jump", true)
						entity.I1 = mod:GetSign(isSiblingDead)
					end


					-- Do the attack with the sibling
					if sibling and isSiblingDead == false then
						resetVariables(sibling)
						sibling.State = entity.State
						siblingSprite:Play(sprite:GetAnimation(), true)

						-- For the jump attack
						if attack == 3 then
							sibling.StateFrame = 10
						end
					end

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end
			end



		--[[ Rollin' ]]--
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
					elseif (entity.GroupIdx >= 1 and not data.enraged) or entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
						vector = -vector

					-- At the sibling's corpse if it exists
					elseif sibling and isSiblingDead == true then
						vector = (entity.Child.Position - entity.Position):Normalized()
					end

					entity.Velocity = vector

					-- Animation
					local suffix = entity.Velocity.Y < 0 and "Up" or ""
					sprite:Play(prefix .. "RollLoop" .. suffix, true)
					sprite:SetFrame(entity.Velocity.Y < 0 and 2 or 3)
				end

			-- Rollin' around
			elseif entity.StateFrame == 1 then
				entity.Velocity = mod:Lerp(entity.Velocity, entity.Velocity:Resized(Settings.RollSpeed), 0.3)

				local suffix = entity.Velocity.Y < 0 and "Up" or ""
				mod:LoopingAnim(sprite, prefix .. "RollLoop" .. suffix)
				sprite.PlaybackSpeed = entity.Velocity:Length() * 0.11
				mod:FlipTowardsMovement(entity, sprite)

				-- Bounce off of obstacles
				if entity:CollidesWithGrid() then
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)
					Game():ShakeScreen(math.floor(entity.Scale * 4))
				end

				-- Stop
				if entity.I1 <= 0 then
					entity.StateFrame = 2
					sprite:Play(prefix .. "RollStop", true)
					sprite.PlaybackSpeed = 1
					entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
					mod:PlaySound(entity, SoundEffect.SOUND_FAT_WIGGLE)

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



		--[[ Laser attack ]]--
		-- Move to position
		elseif entity.State == NpcState.STATE_MOVE then
			-- Get position
			if entity.StateFrame == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

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

				-- Big jump
				if distance > 200 then
					entity.StateFrame = 10
					sprite:Play("Jump", true)

				-- Small jump
				elseif distance > 30 then
					entity.StateFrame = 1
					sprite:Play("SmallJump", true)

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

					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR)
				end

			-- Jumping
			elseif entity.StateFrame == 2 then
				-- Update height
				entity.V2 = Vector(0, entity.V2.Y - Settings.Gravity)
				entity.PositionOffset = Vector(0, math.min(Settings.LandHeight, entity.PositionOffset.Y - entity.V2.Y))

				mod:LoopingAnim(sprite, "JumpSmallLoop")

				-- Land
				if entity.Position:Distance(entity.TargetPosition) < 20 then
					entity.Velocity = mod:StopLerp(entity.Velocity)

					if entity.PositionOffset.Y >= Settings.LandHeight then
						entity.StateFrame = 20
						sprite:Play("SmallLand", true)
						entity.PositionOffset = Vector.Zero
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
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR)
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
					sprite:Play("Land", true)
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

					-- Destroy rocks they land on
					for i = -1, 1 do
						for j = -1, 1 do
							local gridPos = entity.Position + Vector(i * 30, j * 30)
							room:DestroyGrid(room:GetGridIndex(gridPos), true)
						end
					end

					-- Effects
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity):GetSprite().Color = mod.Colors.DustPoof

					-- For big jump
					if sprite:IsPlaying("Land") then
						mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.1)
						Game():ShakeScreen(6)
						Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)

					-- For small jump
					else
						mod:PlaySound(nil, SoundEffect.SOUND_MEAT_IMPACTS)
					end
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
					sprite:Play("LaserStart", true)
					sprite.FlipX = entity.I1 == 1
				end

			-- Start
			elseif entity.StateFrame == 1 then
				if sprite:IsEventTriggered("Jump") then
					mod:PlaySound(nil, SoundEffect.SOUND_SKIN_PULL)
				end

				if sprite:IsFinished() then
					entity.StateFrame = 2

					local angle = 90 + entity.I1 * 90
					local offset = Vector.FromAngle(angle):Resized(10) + Vector(0, -30)

					local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.GIANT_RED, entity.Position, angle, 30, offset, entity), entity}
					data.brim = laser_ent_pair.laser
					data.brim.DepthOffset = entity.DepthOffset - 10

					-- Effect
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 5, entity.Position, Vector.Zero, entity):ToEffect()
					effect:FollowParent(entity)
					effect.DepthOffset = entity.DepthOffset - 90

					local effectSprite = effect:GetSprite()
					effectSprite.Offset = Vector.FromAngle(angle):Resized(18) + Vector(0, -30)
					effectSprite.Scale = Vector(0.7, 0.7)

					local c = mod.Colors.BrimShot
					effectSprite.Color = Color(c.R,c.G,c.B, 0.6, c.RO,c.GO,c.BO)
				end

			-- Loop
			elseif entity.StateFrame == 2 then
				mod:LoopingAnim(sprite, "LaserLoop")

				-- Stop
				if not data.brim:Exists() then
					entity.StateFrame = 3
					sprite:Play("LaserStop", true)

				else
					-- If they collide
					if sibling and sibling:GetData().brim -- Sibling's laser exists
					and entity.Position.Y <= sibling.Position.Y + 100 and entity.Position.Y >= sibling.Position.Y - 100 then -- They're close enough vertically
						local pos = entity.Position + data.brim.PositionOffset * 6 -- No clue why multiplying it makes it work
						local siblingPos = sibling.Position + sibling:GetData().brim.PositionOffset * 6
						data.brim:SetMaxDistance(pos:Distance(siblingPos) / 2)

					else
						data.brim:SetMaxDistance(0)
					end
				end

			-- Stop
			elseif entity.StateFrame == 3 then
				if sprite:IsEventTriggered("Jump") then
					mod:PlaySound(nil, SoundEffect.SOUND_SKIN_PULL, 1, 0.9)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end


		-- Sky Laser
		elseif entity.State == NpcState.STATE_ATTACK3 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Start
			if entity.StateFrame == 0 then
				if sprite:IsEventTriggered("Jump") then
					mod:PlaySound(nil, SoundEffect.SOUND_SKIN_PULL)
				end

				if sprite:IsFinished() then
					entity.StateFrame = 1
					entity.I1 = Settings.SkyLaserDuration

					-- Big fuck you laser
					local pos = entity.Position + (entity.Position - target.Position):Rotated(mod:Random(-15, 15)):Resized(100)
					data.laser = Isaac.Spawn(mod.Entities.Type, mod.Entities.SkyLaser, 0, pos, Vector.Zero, entity)
					data.laser.Parent = entity

					-- Laser visual
					local laserVisual = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.SkyLaserEffect, 0, entity.Position, Vector.Zero, entity):ToEffect()
					laserVisual:FollowParent(entity)
					laserVisual.DepthOffset = entity.DepthOffset + 10
					data.laser.Child = laserVisual

					-- Effect
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 5, entity.Position, Vector.Zero, entity):ToEffect()
					effect:FollowParent(entity)
					effect.DepthOffset = entity.DepthOffset - 80

					local effectSprite = effect:GetSprite()
					effectSprite.Offset = Vector(0, -25)
					effectSprite.Scale = Vector(0.7, 0.7)

					local c = mod.Colors.BrimShot
					effectSprite.Color = Color(c.R,c.G,c.B, 0.6, c.RO,c.GO,c.BO)
				end

			-- Loop
			elseif entity.StateFrame == 1 then
				mod:LoopingAnim(sprite, "AngryLaserLoop")

				-- Stop
				if entity.I1 <= 0 then
					entity.StateFrame = 2
					sprite:Play("AngryLaserStop", true)
					mod:FlipTowardsTarget(entity, sprite)
					data.laser.Parent = nil

				else
					entity.I1 = entity.I1 - 1
				end

			-- Stop
			elseif entity.StateFrame == 2 then
				if sprite:IsEventTriggered("Jump") then
					mod:PlaySound(nil, SoundEffect.SOUND_SKIN_PULL, 1, 0.9)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end



		--[[ Jump attack ]]--
		-- Jump on sibling / wait for sibling
		elseif entity.State == NpcState.STATE_JUMP then
			-- Jump
			if entity.StateFrame == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Jump") then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR)
				end

				if sprite:IsFinished() then
					entity.StateFrame = 1
				end

			-- Jumping
			elseif entity.StateFrame == 1 then
				mod:LoopingAnim(sprite, "JumpLoop")

				-- Land
				if entity.Position:Distance(sibling.Position) < 10 then
					entity.StateFrame = 2
					sprite:Play(prefix .. "Land", true)
					entity.Velocity = Vector.Zero

				-- Move to position
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (sibling.Position - entity.Position):Resized(Settings.JumpSpeed), 0.25)
				end

			-- Landing
			elseif entity.StateFrame == 2 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				-- Only land on the sibling if it's not transitioning and on the ground
				if sibling.State ~= NpcState.STATE_SPECIAL and sibling.PositionOffset.Y >= 0
				and sprite:IsEventTriggered("Jump") then
					entity.StateFrame = 3
					sprite:Play(prefix .. "ComboTop", true)
					entity.Position = sibling.Position
					entity.Velocity = Vector.Zero

					-- Set the sibling's state
					sibling.State = entity.State
					sibling.StateFrame = 11


					-- Dead sibling
					if isSiblingDead == true then
						siblingSprite:Play("CorpseBottom" .. sibling:GetData().corpseAnim, true)

						-- Effects
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, sibling.Position, Vector.Zero, sibling)
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, sibling.Position, Vector.Zero, sibling)
						mod:PlaySound(nil, SoundEffect.SOUND_MEAT_FEET_SLOW0)

					-- Alive sibling
					else
						siblingSprite:Play("ComboBottom", true)

						-- Effects
						local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity):GetSprite()
						effect.Color = mod.Colors.DustPoof
						effect.Offset = Vector(0, -10)
						mod:PlaySound(nil, SoundEffect.SOUND_MEAT_IMPACTS)
					end
				end


				-- If the sibling died before she could land on her
				if sprite:IsEventTriggered("Land") then
					entity.Velocity = Vector.Zero
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

					-- Effects
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity):GetSprite().Color = mod.Colors.DustPoof
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.1)
					Game():ShakeScreen(6)
					Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end


			-- Landed on sibling
			elseif entity.StateFrame == 3 then
				-- Jumped
				if sprite:WasEventTriggered("Jump") then
					entity.Velocity = mod:StopLerp(entity.Velocity)

				-- Still on
				else
					entity.Position = sibling.Position
					entity.Velocity = sibling.Velocity

					-- Fall off if the sibling dies under her
					if entity.I1 ~= mod:GetSign(isSiblingDead) then
						entity.StateFrame = 20
						entity.PositionOffset = Vector(0, -30)
						entity.V2 = Vector(0, -1)
					end
				end

				if sprite:IsEventTriggered("Jump") then
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR)
					mod:PlaySound(nil, SoundEffect.SOUND_FETUS_JUMP, 1.5)
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

				-- Go back to being idle if the sibling dies
				if entity.I1 ~= mod:GetSign(isSiblingDead) then
					entity.State = NpcState.STATE_IDLE
				end

			-- Launch the sibling
			elseif entity.StateFrame == 11 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				-- Cancel the launch if the sibling dies
				if isSiblingDead == true and not sprite:WasEventTriggered("Jump") then
					entity.StateFrame = 21
					sprite:Play("Land", true)
					sprite:SetFrame(10)
				end

				if sprite:IsFinished() then
					entity.StateFrame = 10
				end


			-- Fall off
			elseif entity.StateFrame == 20 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				-- Update height
				entity.V2 = Vector(0, entity.V2.Y - Settings.Gravity)
				entity.PositionOffset = Vector(0, math.min(Settings.LandHeight, entity.PositionOffset.Y - entity.V2.Y))

				mod:LoopingAnim(sprite, "SmallJumpLoop")

				-- Land
				if entity.PositionOffset.Y >= Settings.LandHeight then
					entity.StateFrame = 21
					sprite:Play("SmallLand", true)
					entity.PositionOffset = Vector.Zero
				end

			-- Landed
			elseif entity.StateFrame == 21 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Land") then
					entity.Velocity = Vector.Zero
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_IMPACTS)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end


		-- Launched
		elseif entity.State == NpcState.STATE_STOMP then
			-- Moving to position
			if entity.StateFrame == 0 then
				mod:LoopingAnim(sprite, "JumpLoop")

				-- Land
				if entity.Position:Distance(entity.TargetPosition) < 20 then
					entity.StateFrame = 1
					sprite:Play(prefix .. "Land", true)
					mod:FlipTowardsMovement(entity, sprite)

				-- Move to position
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(Settings.JumpSpeed), 0.25)
				end

			-- Landing
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
					params.CircleAngle = mod:Random(10, 100) * 0.01
					entity:FireProjectiles(entity.Position, Vector(11, 6), 9, params)

					params.Scale = 1.35
					params.BulletFlags = ProjectileFlags.NO_WALL_COLLIDE + (entity.GroupIdx == 1 and ProjectileFlags.CURVE_LEFT or ProjectileFlags.CURVE_RIGHT)
					entity:FireProjectiles(entity.Position, Vector(7.5, 6), 9, params)

					-- Shockwave
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SHOCKWAVE, 0, entity.Position, Vector.Zero, entity)

					-- Effects
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity):GetSprite().Color = mod.Colors.DustPoof
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.1)
					mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1.1)
					Game():ShakeScreen(12)
					Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)

					-- Launch dead siblings
					for i, sister in pairs(Isaac.FindByType(entity.Type, entity.Variant, -1, false, true)) do
						if sister:GetData().corpse then
							local sister = sister:ToNPC()

							-- Don't launch if already launched or there is a sister on top of her
							if not (sister.State == NpcState.STATE_STOMP and sister.StateFrame == 0) and not (sister.State == NpcState.STATE_JUMP and sister.StateFrame == 11) then
								sister.State = NpcState.STATE_STOMP
								sister.StateFrame = 0
								sister.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
								sister.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
								sister.V2 = Vector(0, Settings.CorpseJumpStrength)

								-- Get velocity
								sister.Velocity = mod:RandomVector(mod:Random(20, 40) / 10)

								mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 1.1)
							end
						end
					end
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE

					-- Set the sibling back to the idle state
					if isSiblingDead == false then
						sibling.State = NpcState.STATE_IDLE
					end
				end
			end



		--[[ Transition ]]--
		elseif entity.State == NpcState.STATE_SPECIAL then
			if sprite:IsEventTriggered("Jump") then
				data.enraged = true
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end
		end





	--[[ Corpse moding ]]--
	else
		--[[ Fake death ]]--
		if entity.State == NpcState.STATE_SPECIAL then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Recreate blood death animation
			if sprite:IsEventTriggered("BloodStart") then
				entity.I2 = 1
			elseif sprite:IsEventTriggered("BloodStop") then
				entity.I2 = 0
			end

			if entity.I2 == 1 and entity:IsFrame(math.random(3, 4), 0) then
				mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.9)

				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 0, entity.Position, Vector.Zero, entity)
				effect.DepthOffset = entity.DepthOffset + 10
				effect:GetSprite().Offset = Vector(math.random(-40, 40), -20 + math.random(-40, 40))

				local effectScale = 1 + (math.random(0, 20) * -0.01)
				effect:GetSprite().Scale = Vector(effectScale, effectScale)
			end


			-- Switch animations
			if sprite:IsEventTriggered("Jump") then
				data.corpseAnim = mod:Random(1, 3)
				sprite:Play("CorpseRollStop" .. data.corpseAnim, true)

				-- Effects
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity)
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity)
				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.9)
				mod:PlaySound(nil, SoundEffect.SOUND_MEAT_FEET_SLOW0, 1.1)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end



		--[[ Chillin' ]]--
		elseif entity.State == NpcState.STATE_IDLE then
			entity.Velocity = mod:StopLerp(entity.Velocity)
			mod:LoopingAnim(sprite, "CorpseIdle" .. data.corpseAnim)



		--[[ Rollin' ]]--
		elseif entity.State == NpcState.STATE_ATTACK then
			if entity.StateFrame <= 1 then
				entity.Velocity = mod:Lerp(entity.Velocity, entity.Velocity:Resized(Settings.RollSpeed), 0.3)

				local suffix = entity.Velocity.Y < 0 and "Up" or ""
				mod:LoopingAnim(sprite, "CorpseRollLoop" .. suffix)
				sprite.PlaybackSpeed = entity.Velocity:Length() * 0.11
				mod:FlipTowardsMovement(entity, sprite)

				-- Bounce off of obstacles
				if entity:CollidesWithGrid() then
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)
					Game():ShakeScreen(math.floor(entity.Scale * 4))

					-- Stop
					if entity.I1 >= Settings.CorpseBounces - 1 then
						entity.StateFrame = 2
						data.corpseAnim = mod:Random(1, 3)
						sprite:Play("CorpseRollStop" .. data.corpseAnim, true)
						sprite.PlaybackSpeed = 1
						entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

						-- Projectiles
						local params = ProjectileParams()
						params.Scale = 1.25
						entity:FireBossProjectiles(12, Vector.Zero, 2, params)

						-- Effects
						mod:PlaySound(nil, SoundEffect.SOUND_MEAT_FEET_SLOW0, 1.1, 0.95)
						mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 0.8)

						local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):GetSprite()
						effect.Offset = Vector(0, -15)
						effect.Scale = Vector(0.9, 0.9)

					else
						entity.I1 = entity.I1 + 1
					end
				end

			-- Splattered on the wall
			elseif entity.StateFrame == 2 then
				entity.Velocity = mod:Lerp(entity.Velocity, Vector.Zero, 0.15)

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end



		--[[ Jump attack ]]--
		elseif entity.State == NpcState.STATE_JUMP then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Waiting for sibling
			if entity.StateFrame == 10 then
				mod:LoopingAnim(sprite, "CorpseIdle" .. data.corpseAnim)

			-- Launch the sibling
			elseif entity.StateFrame == 11 then
				-- Projectiles
				if not sprite:WasEventTriggered("Jump") then
					if entity.I1 <= 0 then
						local params = ProjectileParams()
						params.Scale = 1.25
						entity:FireBossProjectiles(3, Vector.Zero, 2, params)
						mod:PlaySound(entity, SoundEffect.SOUND_BLOODSHOOT)
						entity.I1 = 2

					else
						entity.I1 = entity.I1 - 1
					end
				end

				if sprite:IsFinished() then
					entity.StateFrame = 10
				end
			end


		-- Launched
		elseif entity.State == NpcState.STATE_STOMP then
			-- Midair
			if entity.StateFrame == 0 then
				-- Update height
				entity.V2 = Vector(0, entity.V2.Y - Settings.Gravity)
				entity.PositionOffset = Vector(0, math.min(Settings.LandHeight, entity.PositionOffset.Y - entity.V2.Y))

				mod:LoopingAnim(sprite, "CorpseLaunched")
				mod:FlipTowardsMovement(entity, sprite)

				-- Land
				if entity.PositionOffset.Y >= Settings.LandHeight - 20 then
					entity.StateFrame = 1
					data.corpseAnim = mod:Random(1, 3)
					sprite:Play("CorpseLand" .. data.corpseAnim, true)

					entity.PositionOffset = Vector.Zero
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

					-- Projectiles
					local params = ProjectileParams()
					params.Scale = 1.25
					entity:FireBossProjectiles(12, Vector.Zero, 2, params)

					-- Effects
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity)
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity)
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS)
					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 1.1)
					Game():ShakeScreen(6)
				end

			-- Landed
			elseif entity.StateFrame == 1 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end
		end


		-- Creep
		if entity.State ~= NpcState.STATE_SPECIAL and entity.PositionOffset.Y >= 0 and entity:IsFrame(3, 0) then
			mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position + mod:RandomVector(mod:Random(30)), 2, Settings.CreepTime)
		end

		-- Die for real
		if not sibling then
			entity:KillUnique()
			sprite:Play("Death", true)
			sprite:SetFrame(45)
		end
	end



	if entity:HasMortalDamage() then
		-- Replace blood color with default red blood
		entity.SplatColor = Color.Default

		-- Cancel death for the first sister and turn into a corpse
		if not data.corpse and sibling and isSiblingDead == false then
			entity.State = NpcState.STATE_SPECIAL
			sprite:Play("Death", true)
			sprite.PlaybackSpeed = 1

			entity.HitPoints = 1000
			entity.MaxHitPoints = 0
			data.corpse = true
			resetVariables(entity)

			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

			entity:AddEntityFlags(EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_BOSSDEATH_TRIGGERED | EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
			entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

			-- Get rid of the laser
			if data.brim then
				data.brim:SetTimeout(1)
				data.brim = nil
			end
		end
	end

	if entity.FrameCount > 1 then
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

	-- Reduce damage taken if the sibling is dead and it didn't enrage yet
	elseif entity.Child and entity.Child:GetData().corpse and not entity:GetData().enraged and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
		local onePercent = damageAmount / 100
		local reduction = onePercent * Settings.DamageReduction

		entity:TakeDamage(damageAmount - reduction, damageFlags + DamageFlag.DAMAGE_CLONES, damageSource, 1)
		entity:SetColor(mod.Colors.ArmorFlash, 2, 0, false, true)
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
	effect.SpriteOffset = Vector(0, -22)
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