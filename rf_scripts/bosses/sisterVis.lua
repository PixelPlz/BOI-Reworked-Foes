local mod = BetterMonsters

local Settings = {
	Cooldown = 60,

	RollTime = 210,
	RollSpeed = 11,

	CreepTime = 90,
	CorpseBounces = 2, -- Including the final one

	-- Jumping on/off of walls
	Gravity = 1,
	JumpStrength = 8,
	JumpSpeed = 16,
	LandHeight = 8,
}



function mod:sisterVisInit(entity)
	entity.ProjectileCooldown = Settings.Cooldown / 2

	if entity.SpawnerEntity then
		entity.GroupIdx = 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.sisterVisInit, EntityType.ENTITY_SISTERS_VIS)

function mod:sisterVisUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local data = entity:GetData()
	local room = Game():GetRoom()


	-- Get the sibling
	local sibling, siblingSprite
	local isSiblingDead = false

	if entity.Child then
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
				-- Don't do the jump attack if the sibling doesn't exist
				if not sibling or not sibling:Exists() then
					attackCount = 2
				end
				local attack = mod:Random(1, attackCount)
				attack = 1

				-- Roll
				if attack == 1 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("RollStart", true)

				-- Laser
				elseif attack == 2 then
					entity.State = NpcState.STATE_MOVE
					--sprite:Play("JumpSmall", true)

				-- Jump
				elseif attack == 3 then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("Jumping", true)
				end

				-- Do the attack with the sibling
				if sibling and isSiblingDead == false then
					resetVariables(sibling)
					sibling.State = entity.State
					siblingSprite:Play(sprite:GetAnimation(), true)
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

				-- Bounce off of obstacles
				if entity:CollidesWithGrid() then
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)
					Game():ShakeScreen(math.floor(entity.Scale * 4))
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


		-- Jump to position
		elseif entity.State == NpcState.STATE_MOVE then
			-- Get position
			if entity.StateFrame == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)
				mod:LoopingAnim(sprite, "Idle")


				-- Get left and right positions
				local _, posLeft =  room:CheckLine(target.Position, target.Position - Vector(1000, 0), 2, 500, false, false)
				local _, posRight = room:CheckLine(target.Position, target.Position + Vector(1000, 0), 2, 500, false, false)

				-- Get the closest side
				if entity.Position:Distance(posLeft) < sibling.Position:Distance(posLeft) then
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
				if distance > 120 then
					entity.StateFrame = 1
					sprite:Play("JumpSmall", true)

				-- Small jump to position
				elseif distance > 30 then
					entity.StateFrame = 1
					sprite:Play("JumpSmall", true)

				-- Already at the position
				else
					entity.State = NpcState.STATE_ATTACK2
					entity.StateFrame = 0
				end

			-- Jump
			elseif entity.StateFrame == 1 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.StateFrame = 2
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					entity.V2 = Vector(0, Settings.JumpStrength)

					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS)
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8)
				end

			-- Jumping
			elseif entity.StateFrame == 2 then
				-- Update height
				entity.V2 = Vector(0, entity.V2.Y - Settings.Gravity)
				entity.PositionOffset = Vector(0, math.min(Settings.LandHeight, entity.PositionOffset.Y - entity.V2.Y))

				mod:LoopingAnim(sprite, "Midair")
				mod:FlipTowardsMovement(entity, sprite)

				-- Land
				if entity.Position:Distance(entity.TargetPosition) < 20 then
					entity.Velocity = mod:StopLerp(entity.Velocity)

					if entity.PositionOffset.Y >= Settings.LandHeight then
						entity.StateFrame = 3
						sprite:Play("Land", true)
						entity.PositionOffset = Vector.Zero

						-- Effects
						mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.8)
						mod:PlaySound(nil, SoundEffect.SOUND_GOOATTACH0, 1.1)

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

			-- Landed
			elseif entity.StateFrame == 3 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

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
					if sibling:GetData().brim -- Sibling's laser exists
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
					entity:FireBossProjectiles(14, Vector.Zero, 2, ProjectileParams())

				else
					entity.I1 = entity.I1 + 1
				end
			end


		-- Splattered on the wall
		elseif entity.State == NpcState.STATE_STOMP then
			--entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:GetFrame() == 9 then
				entity.State = NpcState.STATE_IDLE
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

		entity.HitPoints = 1000
		entity.MaxHitPoints = 0
		data.corpse = true

		resetVariables(entity)
		entity:AddEntityFlags(EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_BOSSDEATH_TRIGGERED | EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

	elseif entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.sisterVisUpdate, EntityType.ENTITY_SISTERS_VIS)

function mod:sisterVisCollide(entity, target, bool)
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
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.sisterVisCollide, EntityType.ENTITY_SISTERS_VIS)



-- Sky laser
function mod:sisterVisSkyLaserUpdate(effect)
	local sprite = effect:GetSprite()

	-- Start
	if effect.State == 0 then
		if sprite:IsFinished() then
			effect.State = 1
		end

	-- Loop
	elseif effect.State == 1 then
		-- Stop if the parent is dead
		if not effect.Parent or effect.Parent:HasMortalDamage() then
			effect.State = 2
			sprite:Play("End", true)

		-- Move towards parent's target
		else
			local target = effect.Parent:ToNPC():GetPlayerTarget()
			effect.Velocity = mod:Lerp(effect.Velocity, (target.Position - effect.Position):Resized(10), 0.25)
			mod:LoopingAnim(sprite, "Loop")

			-- Creep
			if effect:IsFrame(2, 0) then
				mod:QuickCreep(EffectVariant.CREEP_RED, effect.Parent, effect.Position, 2.5, Settings.CreepTime)
			end
		end

	-- End
	elseif effect.State == 2 then
		effect.Velocity = mod:StopLerp(effect.Velocity)

		if sprite:IsFinished() then
			effect:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.sisterVisSkyLaserUpdate, IRFentities.SisterVisLaser)