local mod = ReworkedFoes



--[[ General functions ]]--

-- Linear interpolate from one number / vector to another by `percent` decimal
---@param first number | Vector
---@param second number | Vector
---@param percent number
---@return number | Vector
function ReworkedFoes:Lerp(first, second, percent)
	return (first + (second - first) * percent)
end

-- Lerp to `Vector.Zero`
---@param vector Vector
---@param percent number? Defaults to `0.25`.
---@return Vector
function ReworkedFoes:StopLerp(vector, percent)
	---@type Vector
	return mod:Lerp(vector, Vector.Zero, percent or 0.25)
end



-- Get sign from a number / boolean
---@param value number | boolean
---@return integer sign 1 or -1
function ReworkedFoes:GetSign(value)
	if (type(value) == "number"  and value >= 1)
	or (type(value) == "boolean" and value == true) then
		return 1
	else
		return -1
	end
end



-- Round a number up or down based on its decimals
---@param number number
---@return integer
function ReworkedFoes:RoundNumber(number)
	if number % 1 >= 0.5 then
		return math.ceil(number)
	else
		return math.floor(number)
	end
end



-- Clamp a number
---@param number number
---@param min number
---@param max number
---@return number
function ReworkedFoes:ClampNumber(number, min, max)
	return math.min( math.max(number, min), max)
end

-- Clamp a vector
---@param vector Vector
---@param clampDegrees number
---@return Vector
function ReworkedFoes:ClampVector(vector, clampDegrees)
	local length = vector:Length()
	local timesClampDegree = vector:GetAngleDegrees() / clampDegrees
	timesClampDegree = mod:RoundNumber(timesClampDegree)
	return Vector.FromAngle(clampDegrees * timesClampDegree):Resized(length)
end



-- Convert degrees to radians. Equivalent to `math.rad()`
---@param degrees number
---@return number
function ReworkedFoes:DegreesToRadians(degrees)
	return degrees * math.pi / 180
end


-- Align a position to the grid
---@param position Vector
---@return Vector
function ReworkedFoes:GridAlignedPosition(position)
	local room = Game():GetRoom()
	return room:GetGridPosition(room:GetGridIndex(position))
end


-- Get angle degrees (improved)
---@param input Vector | number
---@return number
function ReworkedFoes:GetPositiveAngleDegrees(input)
	local angle

	if type(input) == "number" then
		angle = input
	else
		angle = input:GetAngleDegrees()
	end

	return angle % 360
end



-- Get angle difference (but good)
---@param first Vector | number
---@param second Vector | number
---@return number
function ReworkedFoes:GetAngleDifference(first, second)
	first  = mod:GetPositiveAngleDegrees(first)
	second = mod:GetPositiveAngleDegrees(second)
	local sub = first - second
	return math.abs((sub + 180) % 360 - 180)
end



-- NPC shoot function but it returns the projectile(s)
---@param entity EntityNPC
---@param from Vector
---@param velocity Vector
---@param shootType integer
---@param params ProjectileParams?
---@param trailColor Color? Gives the projectiles a Haemolacria-like trail.
---@return EntityProjectile | table
function ReworkedFoes:FireProjectiles(entity, from, velocity, shootType, params, trailColor)
	if REPENTOGON then
		ReworkedFoes.RecordedProjectiles = entity:FireProjectilesEx(from, velocity, shootType, params or ProjectileParams())

	else
		-- Start recording projectiles
		mod.RecordedProjectiles = {}
		mod.RecordProjectiles = true

		-- Shoot projectiles
		entity:FireProjectiles(from, velocity, shootType, params or ProjectileParams())

		-- Stop recording
		mod.RecordProjectiles = false
	end


	-- Return the projectiles (seriously, why doesn't the vanilla one do it?)
	if #mod.RecordedProjectiles > 1 then
		-- Apply trail
		if trailColor then
			for i, projectile in pairs(mod.RecordedProjectiles) do
				projectile:GetData().trailColor = trailColor
			end
		end
		return mod.RecordedProjectiles

	else
		-- Apply trail
		if trailColor then
			mod.RecordedProjectiles[1]:GetData().trailColor = trailColor
		end
		return mod.RecordedProjectiles[1]
	end
end



-- Better sound function
---@param entity EntityNPC? Optionally provide `nil` to play sound from SFXManager.
---@param id integer
---@param volume number? Default is `1`.
---@param pitch number? Default is `1`.
---@param cooldown integer? Also known as `FrameDelay`, default is `0`.
---@param loop boolean? Default is `false`.
---@param pan number? Default is `0`.
function ReworkedFoes:PlaySound(entity, id, volume, pitch, cooldown, loop, pan)
	volume = volume or 1
	pitch = pitch or 1
	cooldown = cooldown or 0
	pan = pan or 0

	if entity then
		entity:ToNPC():PlaySound(id, volume, cooldown, loop or false, pitch)
	else
		SFXManager():Play(id, volume, cooldown, loop, pitch, pan)
	end
end



-- Room shape flags
---@enum RoomShapeFlags
ReworkedFoes.RoomShapeFlags = {
	Tiny  = 1 << 0,
	Tall  = 1 << 1,
	Long  = 1 << 2,
	L 	  = 1 << 3,
	Short = 1 << 4,
	Thin  = 1 << 5,
}

-- Gets the bitset of the room's shape flags for easily checking groups of room shapes
-- Eg. `mod:GetRoomShapeFlags() & mod.RoomShapeFlags.Tall > 0` will return `true` in 1x2, 2x2 and all L shaped rooms.
---@return integer
function ReworkedFoes:GetRoomShapeFlags()
	local shape = Game():GetRoom():GetRoomShape()
	local flags = 0

	-- Closet rooms
	if shape == RoomShape.ROOMSHAPE_IH  or shape == RoomShape.ROOMSHAPE_IV
	or shape == RoomShape.ROOMSHAPE_IIV or shape == RoomShape.ROOMSHAPE_IIH then
		flags = flags + mod.RoomShapeFlags.Tiny

		-- Short (horizontal) closet rooms
		if shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IIH then
			flags = flags + mod.RoomShapeFlags.Short
		-- Thin (vertical) closet rooms
		else
			flags = flags + mod.RoomShapeFlags.Thin
		end
	end

	-- Tall rooms
	if shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV
	or shape >= RoomShape.ROOMSHAPE_2x2 then
		flags = flags + mod.RoomShapeFlags.Tall
	end

	-- Long rooms
	if shape >= RoomShape.ROOMSHAPE_2x1 then
		flags = flags + mod.RoomShapeFlags.Long
	end

	-- L shaped rooms
	if shape >= RoomShape.ROOMSHAPE_LTL then
		flags = flags + mod.RoomShapeFlags.L
	end

	return flags
end



-- Check if the game is in hard mode
---@return boolean
function ReworkedFoes:IsHardMode()
	return Game().Difficulty % 2 == 1
end





--[[ RNG functions ]]--

-- General RNG function
---@param min number? You may only omit this if you're also omitting `max`, which will make it use `RandomFloat()`.
---@param max number? Omit when providing a `min` for `rng:RandomInt(min + 1)`.
---@param rng RNG? Omit to use a generic RNG object.
function ReworkedFoes:Random(min, max, rng)
	rng = rng or mod.RNG

	-- Float
	if not min and not max then
		return rng:RandomFloat()

	-- Integer
	elseif min and not max then
		return rng:RandomInt(min + 1)

	-- Range
	else
		local difference = math.abs(min)

		-- For ranges with negative numbers
		if min < 0 then
			max = max + difference
			return rng:RandomInt(max + 1) - difference
		-- For positive only
		else
			max = max - difference
			return rng:RandomInt(max + 1) + difference
		end
	end
end



-- Get a vector with a random angle
---@param length number? Omit to get a unit vector.
function ReworkedFoes:RandomVector(length)
	local vector = Vector.FromAngle(mod:Random(359))
	if length then
		vector = vector:Resized(length)
	end
	return vector
end



-- Get a random sign
---@return integer -1 or 1.
function ReworkedFoes:RandomSign()
	if mod:Random(1) == 0 then
		return -1
	end
	return 1
end



-- Get a random index from a table.
---@param fromTable table An array.
---@param rng RNG? Omit to use a generic RNG object.
---@return any
function ReworkedFoes:RandomIndex(fromTable, rng)
	return fromTable[mod:Random(1, #fromTable, rng)]
end





--[[ Sprite functions ]]--

-- Looping animation
---@param sprite Sprite
---@param anim string? Default is `Idle`.
---@param dontReset boolean? Default is `false`.
function ReworkedFoes:LoopingAnim(sprite, anim, dontReset)
	anim = anim or "Idle"

	if not sprite:IsPlaying(anim) then
		if dontReset then
			sprite:SetAnimation(anim, false)
		else
			sprite:Play(anim, true)
		end
	end
end

-- Looping overlay
---@param sprite Sprite
---@param anim string
---@param priority boolean? Default is `false`.
function ReworkedFoes:LoopingOverlay(sprite, anim, priority)
	if not sprite:IsOverlayPlaying(anim) then
		if priority then
			sprite:SetOverlayRenderPriority(priority)
		end
		sprite:PlayOverlay(anim, true)
	end
end



-- Flip towards the entity's movement
---@param entity Entity
---@param sprite Sprite
---@param otherWay boolean? Usually, if moving towards the left, the entity will get `FlipX` set to true. Set this to `true` for the opposite of that. Defaults to `false`.
function ReworkedFoes:FlipTowardsMovement(entity, sprite, otherWay)
	if (otherWay ~= true and entity.Velocity.X < 0)
	or (otherWay == true and entity.Velocity.X > 0) then
		sprite.FlipX = true
	else
		sprite.FlipX = false
	end
end

-- Flip towards the entity's target
---@param entity Entity
---@param sprite Sprite
---@param otherWay boolean? Usually, if moving towards the left, the entity will get `FlipX` set to true. Set this to `true` for the opposite of that. Defaults to `false`.
function ReworkedFoes:FlipTowardsTarget(entity, sprite, otherWay)
	local target = entity:ToNPC() and entity:GetPlayerTarget() or entity.Target

	if (otherWay ~= true and target.Position.X < entity.Position.X)
	or (otherWay == true and target.Position.X > entity.Position.X) then
		sprite.FlipX = true
	else
		sprite.FlipX = false
	end
end



-- Get direction string from angle degrees
---@param angleDegrees number
---@param noSeparateHorizontal boolean? If `true`, returns "Hori" if moving horizontally. Defaults to `false`.
---@param useSide boolean? If `true`, returns "Side" instead of "Hori" if moving horizontally. Defaults to `false`.
---@param noSeparateVertical boolean? If `true`, returns "Vert" if moving vertically. Defaults to `false`.
---@return string
function ReworkedFoes:GetDirectionString(angleDegrees, noSeparateHorizontal, useSide, noSeparateVertical)
	-- Vertical
	if (angleDegrees >= 45 and angleDegrees <= 135) or (angleDegrees < -45 and angleDegrees > -135) then
		-- Combined
		if noSeparateVertical == true then
			return "Vert"

		-- Up / Down
		elseif angleDegrees >= 45 and angleDegrees <= 135 then
			return "Down"
		else
			return "Up"
		end

	-- Horizontal
	else
		-- Combined
		if noSeparateHorizontal == true then
			return useSide == true and "Side" or "Hori"

		-- Left / Right
		elseif angleDegrees > -45 and angleDegrees < 45 then
			return "Right"
		else
			return "Left"
		end
	end
end

-- Gets cardinal and orthogonal directional strings (e.g. "Right" and "DownRight")
---@param angleDegrees number
---@return string
function ReworkedFoes:GetDirectionStringEX(angleDegrees)
	if angleDegrees >= -22.5 and angleDegrees <= 22.5 then
		return "Right"
	elseif angleDegrees > 22.5 and angleDegrees < 67.5 then
		return "DownRight"
	elseif angleDegrees >= 67.5 and angleDegrees <= 112.5 then
		return "Down"
	elseif angleDegrees > 112.5 and angleDegrees < 157.5 then
		return "DownLeft"
	elseif angleDegrees < -22.5 and angleDegrees > -67.5 then
		return "UpRight"
	elseif angleDegrees <= -67.5 and angleDegrees >= -112.5 then
		return "Up"
	elseif angleDegrees < -112.5 and angleDegrees > -157.5 then
		return "UpLeft"
	else
		return "Left"
	end
end





--[[ Entity functions ]]--

-- Check if the entity is feared
---@param entity Entity
---@return boolean
function ReworkedFoes:IsFeared(entity)
	if entity:HasEntityFlags(EntityFlag.FLAG_FEAR)
	or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
		return true
	end
	return false
end

-- Check if the entity is confused
---@param entity Entity
---@return boolean
function ReworkedFoes:IsConfused(entity)
	return entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION)
end

-- Check if the entity is charmed or friendly
---@param entity Entity
---@return boolean
function ReworkedFoes:IsCharmed(entity)
	if entity:HasEntityFlags(EntityFlag.FLAG_CHARM)
	or entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
		return true
	end
	return false
end

-- Check if the entity is slowed
---@param entity Entity
---@return boolean
function ReworkedFoes:IsSlowed(entity)
	if entity:HasEntityFlags(EntityFlag.FLAG_SLOW)
	or entity:HasEntityFlags(EntityFlag.FLAG_WEAKNESS) then
		return true
	end
	return false
end

-- Check if the entity is frozen / petrified
---@param entity Entity
---@return boolean
function ReworkedFoes:IsFrozen(entity)
	if entity:HasEntityFlags(EntityFlag.FLAG_FREEZE)
	or entity:HasEntityFlags(EntityFlag.FLAG_MIDAS_FREEZE)
	or entity:HasEntityFlags(EntityFlag.FLAG_ICE_FROZEN)
	or entity:HasEntityFlags(EntityFlag.FLAG_HELD) then
		return true
	end
	return false
end

-- Check if the entity can be knocked back / pushed around
---@param entity Entity
---@return boolean
function ReworkedFoes:CanTakeKnockback(entity)
	if entity:HasEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
	or entity:HasEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	or entity.Mass >= 100 then
		return false
	end
	return true
end



-- Get target vector that's affected by status effects
---@param entity EntityNPC
---@param target? Entity
---@return Vector
function ReworkedFoes:GetTargetVector(entity, target)
	target = target or entity:GetPlayerTarget()
	local vector = target.Position - entity.Position

	-- Confused
	if mod:IsConfused(entity) then
		vector = mod:RandomVector()
	-- Feared
	elseif mod:IsFeared(entity) then
		vector = entity.Position - target.Position
	end

	return vector:Normalized()
end



-- Chase player
---@param entity EntityNPC
---@param speed number
function ReworkedFoes:ChasePlayer(entity, speed)
	local target = entity:GetPlayerTarget()

	-- Move randomly if confused
	if mod:IsConfused(entity) then
		mod:WanderAround(entity, speed)

	else
		-- Reverse movement if feared
		if mod:IsFeared(entity) then
			speed = -speed
		end

		-- If there is a path to the player
		if entity.Pathfinder:HasPathToPos(target.Position) or entity:IsFlying() then
			-- If there is a direct line to the player
			if Game():GetRoom():CheckLine(entity.Position, target.Position, LineCheckMode.RAYCAST) or entity:IsFlying() then
				entity.Velocity = mod:Lerp(entity.Velocity, (target.Position - entity.Position):Resized(speed), 0.25)
			else
				entity.Pathfinder:FindGridPath(target.Position, speed / 6, 500, false)
			end

		-- Otherwise stay still
		else
			entity.Velocity = mod:StopLerp(entity.Velocity)
		end
	end
end



-- Wander around randomly
---@param entity EntityNPC
---@param speed number
function ReworkedFoes:WanderAround(entity, speed)
	-- Chase if charmed of friendly / Run away if feared
	if (mod:IsFeared(entity) or mod:IsCharmed(entity)) and not mod:IsConfused(entity) then
		mod:ChasePlayer(entity, speed)

	else
		local data = entity:GetData()

		-- Get the direction to move in and the time to move for in it
		if not data.WanderData or data.WanderData.Timer <= 0 then
			data.WanderData = { Vector = mod:RandomVector(), Timer = mod:Random(15, 45), }
		end

		-- Turn around when colliding with an obstacle
		if entity:CollidesWithGrid() then
			data.WanderData.Vector = entity.Velocity:Normalized()
		end
		entity.Velocity = mod:Lerp(entity.Velocity, data.WanderData.Vector:Resized(speed), 0.25)

		data.WanderData.Timer = data.WanderData.Timer - 1
	end
end



-- Grid aligned random movement
---@param entity EntityNPC
---@param speed number
---@param canFly boolean? Defaults to `false`.
---@param dontDoubleBack boolean? If `true`, prevents the entity from turning 180 degrees unless necessary.
function ReworkedFoes:MoveRandomGridAligned(entity, speed, canFly, dontDoubleBack)
	local data = entity:GetData()
	local room = Game():GetRoom()

	-- Align my position to the grid
	local gridAlignedPos = mod:GridAlignedPosition(entity.Position)

	-- Get which grids I can't go over
	local maxValidGridCol = GridCollisionClass.COLLISION_NONE
	if canFly == true then
		maxValidGridCol = GridCollisionClass.COLLISION_SOLID
	end

	-- Get the grid collision in front of me
	local vector = entity.Velocity:Normalized()
	if data.movementDirection then
		vector = Vector.FromAngle(data.movementDirection * 90)
	end
	local gridInFrontOfMe = room:GetGridIndex(gridAlignedPos + vector * 40)
	local collisionInFrontOfMe = room:GetGridCollision(gridInFrontOfMe)

	-- Don't go into spikes
	local areThereSpikesInFrontOfMe = false
	local gridEntityInFrontOfMe = room:GetGridEntity(gridInFrontOfMe)

	if canFly ~= true and gridEntityInFrontOfMe ~= nil and gridEntityInFrontOfMe:ToSpikes() ~= nil then
		areThereSpikesInFrontOfMe = true
	end

	-- Check for either fear or charm
	local fearedOrCharmed = mod:IsFeared(entity) or mod:IsCharmed(entity)


	-- Get valid directions
	if not data.movementDirection or collisionInFrontOfMe > maxValidGridCol or data.moveTimer <= 0 or areThereSpikesInFrontOfMe == true then
		local validDirections = {}

		-- Check all directions
		for i = 1, 4 do
			local checkGrid = gridAlignedPos + (Vector.FromAngle(i * 90) * 40)
			local gridCollision = room:GetGridCollisionAtPos(checkGrid)

			local opposite = i + 2
			if i > 2 then
				opposite = i - 2
			end

			if gridCollision <= maxValidGridCol and (dontDoubleBack ~= true or opposite ~= data.movementDirection) then
				table.insert(validDirections, i)
			end
		end


		-- Failsafe
		if #validDirections <= 0 then
			data.movementDirection = 0

		-- Choose a valid direction
		else
			local chosenDirection = mod:RandomIndex(validDirections)

			if fearedOrCharmed then
				for i, direction in pairs(validDirections) do
					local currentChosenPosition = gridAlignedPos + (Vector.FromAngle(chosenDirection * 90) * 40)
					local checkPos = gridAlignedPos + (Vector.FromAngle(direction * 90) * 40)
					local nearestPlayer = Game():GetNearestPlayer(entity.Position).Position

					if (mod:IsFeared(entity)  and checkPos:Distance(nearestPlayer) > currentChosenPosition:Distance(nearestPlayer))
					or (mod:IsCharmed(entity) and checkPos:Distance(nearestPlayer) < currentChosenPosition:Distance(nearestPlayer)) then
						chosenDirection = direction
					end
				end
			end

			data.movementDirection = chosenDirection
		end

		data.moveTimer = mod:Random(1, 4)
		data.currentIndex = room:GetGridIndex(entity.Position)
	end


	-- Move in the selected direction
	local targetPos = (gridAlignedPos + Vector.FromAngle(data.movementDirection * 90) * 40)
	entity.Velocity = mod:Lerp(entity.Velocity, (targetPos - entity.Position):Resized(speed), 0.35)

	if room:GetGridIndex(entity.Position) ~= data.currentIndex then
		-- Feared and charmed enemies always try to change directions as soon as they can
		if fearedOrCharmed then
			data.moveTimer = 0
		else
			data.moveTimer = data.moveTimer - 1
		end
	end
	data.currentIndex = room:GetGridIndex(entity.Position)
end



-- Bounce around diagonally
---@param entity EntityNPC
---@param speed number
---@param lerpStep number? This function uses `mod:Lerp(start, finish, percentage)` for changing `entity.Velocity`. How much does it lerp by? Defaults to `0.1`.
function ReworkedFoes:MoveDiagonally(entity, speed, lerpStep)
	-- Move randomly if confused
	if mod:IsConfused(entity) then
		mod:WanderAround(entity, speed)


	-- Run away if feared
	elseif mod:IsFeared(entity) then
		local nearest = Game():GetNearestPlayer(entity.Position)
		entity.Velocity = mod:Lerp(entity.Velocity, (entity.Position - nearest.Position):Resized(speed * 2), 0.25)


	-- Regular behaviour
	else
		local xV = speed
		local yV = speed

		if entity.Velocity.X < 0 then
			xV = xV * -1
		end
		if entity.Velocity.Y < 0 then
			yV = yV * -1
		end

		entity.Velocity = mod:Lerp(entity.Velocity, Vector(xV, yV), lerpStep or 0.1)
	end
end



-- Mulligan-type movement
---@param entity EntityNPC
---@param radius number The distance the entity will start avoiding the player.
---@param wanderSpeed number When no player is nearby.
---@param runSpeed number
---@param canFly boolean? Defaults to `false`.
function ReworkedFoes:AvoidPlayer(entity, radius, wanderSpeed, runSpeed, canFly)
	-- Get nearest player
	local nearest = Game():GetNearestPlayer(entity.Position)


	-- Chase if charmed of friendly
	if mod:IsCharmed(entity) then
		mod:ChasePlayer(entity, wanderSpeed + (runSpeed - wanderSpeed) / 2)


	-- Run away if there are players in radius
	elseif nearest.Position:Distance(entity.Position) <= radius and not mod:IsConfused(entity) then
		-- Get target position
		local room = Game():GetRoom()
		local vector = (entity.Position - nearest.Position):Normalized()
		local targetPos = entity.Position + vector:Resized(radius)


		-- Go around obstacles
		if entity.Pathfinder:HasPathToPos(targetPos) or (canFly == true and room:IsPositionInRoom(targetPos, 0)) then
			if room:CheckLine(entity.Position, targetPos, 0) or canFly == true then
				entity.Velocity = mod:Lerp(entity.Velocity, (targetPos - entity.Position):Resized(runSpeed), 0.25)
			else
				entity.Pathfinder:FindGridPath(targetPos, runSpeed / 6, 500, false)
			end


		-- Cornered
		else
			local data = entity:GetData()

			-- Wander in a random direction to try to get unstuck
			if not data.wanderTimer then
				data.wanderTimer = 60
				data.wanderDirection = Vector.Zero
				data.wandering = false

			elseif data.wanderTimer <= 0 then
				data.wanderDirection = (nearest.Position - entity.Position):Rotated(mod:RandomSign() * mod:Random(20, 60)):Resized(runSpeed)

				if data.wandering == false then
					data.wanderTimer = mod:Random(10, 30)
				else
					data.wanderTimer = mod:Random(30, 90)
				end
				data.wandering = not data.wandering

			else
				data.wanderTimer = data.wanderTimer - 1
			end

			-- Move direction
			if data.wandering == true then
				entity.Velocity = mod:Lerp(entity.Velocity, data.wanderDirection, 0.25)
			else
				entity.Velocity = mod:Lerp(entity.Velocity, vector:Resized(runSpeed), 0.25)
			end
		end


	-- Otherwise wander around randomly
	else
		mod:WanderAround(entity, wanderSpeed)
	end
end



-- Orbit parent
---@param entity EntityNPC
---@param parent Entity? Returns `false` and does nothing if this is omitted or the provided entity doesn't exist.
---@param speed number
---@param distance number Orbit Distance.
---@param group string? Orbit with other enemies of this group. Omit to orbit with other enemies of same type, variant, and subtype.
function ReworkedFoes:OrbitParent(entity, parent, speed, distance, group)
	if parent then
		local data = entity:GetData()

		-- Get which entities to go through
		local others = {}

		-- If they have specified groups
		if group then
			data.orbitalGroup = group

			for i, guy in pairs(Isaac.GetRoomEntities()) do
				if guy:GetData().orbitalGroup and guy:GetData().orbitalGroup == group then
					table.insert(others, guy)
				end
			end

		-- No specified group
		else
			others = Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)
		end


		-- Get orbit index and leader
		local siblingCount = 0
		local leader = nil

		for i, sibling in pairs(others) do
			-- Orbiting the same parent and is on the same "team"
			if sibling:HasCommonParentWithEntity(entity)
			and sibling:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) == entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
				local siblingData = sibling:GetData()

				siblingData.orbitIndex = siblingCount
				siblingCount = siblingCount + 1

				-- Get leader
				if siblingCount == 1 then
					leader = sibling:ToNPC()

				else
					siblingData.orbitLeader = leader

					-- Get leader's rotation direction
					if siblingData.orbitLeader:GetData().orbitDirection then
						siblingData.orbitDirection = siblingData.orbitLeader:GetData().orbitDirection
					end
				end
			end
		end


		-- Get distance between siblings
		local degreesBetweenSiblings = 360 / siblingCount
		data.orbitOffset = data.orbitIndex * degreesBetweenSiblings


		-- Get current rotation
		if not data.orbitRotation then
			data.orbitRotation = 0
		end

		-- Leader
		if data.orbitIndex == 0 then
			-- Become the new leader
			if data.orbitWasntLeader then
				data.orbitRotation = (entity.Position - parent.Position):GetAngleDegrees()
				data.orbitWasntLeader = nil
				data.orbitOffset = 0
			end

			if not data.orbitDirection then
				data.orbitDirection = mod:RandomSign()
			end

			data.orbitRotation = data.orbitRotation + data.orbitDirection * speed

			-- Clamp rotation degrees
			if data.orbitRotation >= 360 then
				data.orbitRotation = data.orbitRotation - 360
			elseif data.orbitRotation < 0 then
				data.orbitRotation = data.orbitRotation + 360
			end

		-- Followers
		elseif data.orbitLeader then
			if data.orbitLeader:Exists() then
				data.orbitRotation = data.orbitLeader:GetData().orbitRotation
				data.orbitWasntLeader = true
			else
				data.orbitLeader = nil
			end
		end


		-- Orbit parent
		local orbitVector = Vector.FromAngle(data.orbitRotation + data.orbitOffset)
		local orbitDistance = parent.Size * parent:ToNPC().Scale + distance
		entity.Position = mod:Lerp(entity.Position, parent.Position + orbitVector:Resized(orbitDistance), 0.1)

		entity.Velocity = parent.Velocity


	-- Return false if the parent doesn't exist
	else
		return false
	end
end



---@enum DirectionCheckMode
ReworkedFoes.DirectionCheckMode = {
	AllowAllDirections = 0,
	OnlyAllowFacing    = 1,
	AllowFacingAndSide = 2,
}

-- Check if the target is aligned cardinally
---@param entity EntityNPC
---@param sideRange number
---@param forwardRange number
---@param lineCheckMode LineCheckMode The Room:CheckLine mode to use.
---@param directionCheckMode DirectionCheckMode How alignment should be checked.
---@param facingAngle number? Defaults to the entity's velocity angle.
---@return boolean | number targetAngle The angle to the target if aligned, otherwise false.
function ReworkedFoes:CheckCardinalAlignment(entity, sideRange, forwardRange, lineCheckMode, directionCheckMode, facingAngle)
	local target = entity:ToNPC() and entity:GetPlayerTarget() or entity.Target

	-- Don't check if there are obstacles in the way
	if Game():GetRoom():CheckLine(entity.Position, target.Position, lineCheckMode) then
		for i = 0, 1 do
			-- Get the position to check
			local lineEnd = Vector(target.Position.X, entity.Position.Y)
			if i == 1 then
				lineEnd = Vector(entity.Position.X, target.Position.Y)
			end

			-- Check if the distances are within range
			if (target.Position - lineEnd):Length() <= sideRange and (entity.Position - lineEnd):Length() <= forwardRange then
				local targetAngle = mod:GetPositiveAngleDegrees(lineEnd - entity.Position)
				local angleDifference = mod:GetAngleDifference(facingAngle or entity.Velocity, targetAngle)
				angleDifference = math.abs(angleDifference)

				if not directionCheckMode or directionCheckMode == 0 -- Allow all directions
				or (directionCheckMode == 1 and angleDifference <= 45) -- Only allow the direction I'm facing
				or (directionCheckMode == 2 and angleDifference <= 135) then -- Allow the direction I'm facing + the directions to my side
					return targetAngle
				end
			end
		end
	end

	return false
end



-- Check if non-render related code should be ran in render callbacks
---@return boolean
function ReworkedFoes:ShouldDoRenderEffects()
	return not (Game():IsPaused() or Game():GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT)
end



-- Ignore Knockout Drops knockback
---@param entity EntityNPC
function ReworkedFoes:IgnoreKnockoutDrops(entity)
	if entity:HasEntityFlags(EntityFlag.FLAG_KNOCKED_BACK) then
		entity:ClearEntityFlags(EntityFlag.FLAG_KNOCKED_BACK)
	end
end



-- Change an entities max health
---@param entity Entity
---@param baseHP number
---@param stageHP? number
function ReworkedFoes:ChangeMaxHealth(entity, baseHP, stageHP)
	local finalHP = baseHP

	-- Get the stage HP
	if stageHP then
		local stage = Game():GetLevel():GetStage()

		-- Custom stages
		if StageAPI and StageAPI.CurrentStage then
			stage = StageAPI.CurrentStage.StageHPNumber
		end

		local preStageFive = math.min(4, stage)
		local postStageFive = mod:ClampNumber(stage - 5, 0, 5)
		finalHP = baseHP + ( preStageFive + 0.8 * postStageFive ) * stageHP
	end

	entity.MaxHitPoints = finalHP
	entity.HitPoints = entity.MaxHitPoints
end



-- Revelations compatibility check for minibosses
---@return boolean
function ReworkedFoes:CheckValidMiniboss()
	if REVEL and REVEL.IsRevelStage(true) then
		return false
	end
	return true
end



-- Check if the given boss is a RF champion
---@param entity Entity
---@param variable string The name of the boss to check for.
---@return boolean
function ReworkedFoes:IsRFChampion(entity, variable)
	if ReworkedFoesChampions and mod.Champions and mod.Champions[variable] then
		return entity.SubType == mod.Champions[variable]
	end
	return false
end

-- Check for Champion sin drop replacement
---@param pickup EntityPickup
---@param entityType EntityType
---@param miniboss string The name of the miniboss to check for.
function ReworkedFoes:CheckMinibossDropReplacement(pickup, entityType, miniboss)
	if pickup.SpawnerType == entityType and pickup.SpawnerEntity
	and mod:IsRFChampion(pickup.SpawnerEntity, miniboss) and mod:CheckValidMiniboss() then
		return true
	end
	return false
end





--[[ Spawning helper functions ]]--

-- Spawn creep easily
---@param type number Creep variant.
---@param spawner Entity | nil Creep spawner.
---@param position Vector Spawn position.
---@param scale number? Sprite scale, defaults to `1`.
---@param timeout number? Defaults to `124`.
---@return EntityEffect
function ReworkedFoes:QuickCreep(type, spawner, position, scale, timeout)
	---@type EntityEffect
	---@diagnostic disable-next-line: assign-type-mismatch
	local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, type, 0, position, Vector.Zero, spawner):ToEffect()
	creep.SpriteScale = Vector.One * (scale or 1)

	if timeout then
		creep:SetTimeout(timeout)
	end

	creep:Update()
	return creep
end



-- Shooting effect
---@param entity Entity The shooter that the effect will follow. If the shooter is an NPC the effect will scale with it.
---@param subtype integer Shoot effect subtype.
---@param offset Vector? An offset or `Vector.Zero`
---@param color Color? Color or `Color.Default`
---@param scale number? Effect scale or `1`.
---@param behind boolean? Depth offset subtracted by 10 if `true`, otherwise added to by 10.
---@return EntityEffect
function ReworkedFoes:ShootEffect(entity, subtype, offset, color, scale, behind)
	local entityScale = entity:ToNPC() and entity:ToNPC().Scale or 1
	offset = offset and entityScale * offset or Vector.Zero
	scale = scale and entityScale * scale or 1

	local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, subtype, entity.Position, Vector.Zero, entity):ToEffect()
	local sprite = effect:GetSprite()

	effect:FollowParent(entity)
	sprite.Offset = offset
	sprite.Color = color or Color.Default
	effect.SpriteScale = Vector.One * scale

	if behind == true then
		effect.DepthOffset = entity.DepthOffset - 10
	else
		effect.DepthOffset = entity.DepthOffset + 10
	end

	if subtype == 5 then
		sprite.PlaybackSpeed = 1.25
	end

	effect:Update()
	return effect
end



-- Tracer effect
---@param spawner Entity
---@param angle number
---@param offset Vector Parent offset.
---@param duration integer? The time it takes for the tracer to fade IN. Doesn't affect the fading out. Defaults to `15`.
---@param width number? Defaults to `1`.
---@param color Color? Defaults to `Color(1,0,0, 0.5)`
---@return EntityEffect tracer The tracer is considered dead when it starts fading out.
function ReworkedFoes:QuickTracer(spawner, angle, offset, duration, width, color)
	local tracer = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GENERIC_TRACER, 0, spawner.Position, Vector.Zero, spawner):ToEffect()
	tracer.TargetPosition = Vector.FromAngle(angle)
	tracer:FollowParent(spawner)
	tracer.ParentOffset = offset

	duration = duration or 15
	tracer.LifeSpan = duration
	tracer.Timeout = duration

	tracer.SpriteScale = Vector(width or 1, 0)
	tracer:GetSprite().Color = color or Color(1,0,0, 0.5)

	tracer:Update()
	return tracer
end



-- Sprite trail (Does not spawn if the parent already has a trail, or if the `Enemy Bullet Trails` mod is enabled and the parent is a projectile)
---@param parent Entity
---@param length number? Defaults to `0.1`.
---@param color Color? Defaults to `Color.Default`.
---@param width number? Set to change the SpriteScale of the trail to `Vector.One * width`.
---@return EntityEffect?
function ReworkedFoes:QuickTrail(parent, length, color, width)
	if not parent:GetData().spriteTrail
	and (parent.Type ~= EntityType.ENTITY_PROJECTILE or not BulletTrails) then -- Don't spawn one for projectiles if Enemy Bullet Trails is enabled
		local vector = Vector(0, parent.Height or parent.PositionOffset.Y)
		local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SPRITE_TRAIL, 0, parent.Position, vector, parent):ToEffect()
		trail.Parent = parent

		trail.MinRadius = length or 0.1
		trail.Color = color or Color.Default

		if width then
			trail.SpriteScale = Vector.One * width
		end

		parent:GetData().spriteTrail = trail
		trail:Update()
		return trail
	end
end



-- Ember particles, on random frames between 5 and 10
---@param entity Entity
---@param offset Vector PositionOffset, multiplied by `entity.Scale`.
---@param radiusModifier number? Include for the radius of spawning on the x-axis to be between `-radiusModifier` and `radiusModifier`.
---@param color Color? Include to change the color of the particles.
function ReworkedFoes:EmberParticles(entity, offset, radiusModifier, color)
	if entity:IsFrame(math.random(5, 10), 0) then
		local radius = math.random(-10, 10)
		if radiusModifier then
			radius = math.random(-radiusModifier, radiusModifier)
		end
		local pos = Vector(entity.Position.X + radius, entity.Position.Y)

		local ember = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.EMBER_PARTICLE, 0, pos, Vector.FromAngle(-90), entity)
		ember.PositionOffset = offset * entity.Scale
		ember.DepthOffset = entity.DepthOffset - 10

		if color then
			ember:GetSprite().Color = color
		end
	end
end



-- Fire ring attack
---@param entity Entity
---@param subtype integer Subtype of the fire jets.
---@param rings integer Amount of rings
---@param delay integer Delay between rings. First ring always spawns immediately.
---@param distance number Distance between rings.
---@param startIndex integer? Which ring to start on, defaults to `0`.
---@param startDistance number? Defaults to `0`, extra starting distance for rings.
---@return EntityEffect timer The timer.
function ReworkedFoes:CreateFireRing(entity, subtype, rings, delay, distance, startIndex, startDistance)
	local pos = entity and entity.Position or Game():GetRoom():GetCenterPos()
	local timer = Isaac.Spawn(EntityType.ENTITY_EFFECT, ReworkedFoes.Entities.FireRingHelper, subtype, pos, Vector.Zero, entity):ToEffect()
	timer.Parent = entity
	timer.LifeSpan = startIndex or 0

	local data = timer:GetData()
	data.Delay = delay
	data.Rings = rings
	data.StartDistance = startDistance
	data.Distance = distance

	return timer
end

function mod:FireRingHelperInit(timer)
	timer.Visible = false
	timer.Timeout = 0
	timer:GetData().Timer = 0
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.FireRingHelperInit, mod.Entities.FireRingHelper)

function mod:FireRingHelperUpdate(timer)
	local data = timer:GetData()

	if data.Timer <= 0 then
		-- Get the amount of fire jets
		local fireCount = math.max(1, timer.LifeSpan * 4)

		for i = 0, fireCount - 1 do
			-- Get position
			local angle = 360 / fireCount * i
			local extraDistance = data.StartDistance or 0
			local pos = timer.Position + Vector.FromAngle(angle):Resized(timer.LifeSpan * data.Distance + extraDistance)

			if Game():GetRoom():IsPositionInRoom(pos, 0) then
				local fire = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_JET, timer.SubType, pos, Vector.Zero, timer.Parent)
				fire.SpriteScale = Vector.One * timer.Scale
			end
		end

		data.Timer = data.Delay
		timer.LifeSpan = timer.LifeSpan + 1
		timer.Timeout = timer.Timeout + 1 -- Always starts at 0
		timer.Scale = math.max(0.1, timer.Scale - timer.Timeout / 10)

		-- Remove self after all rings have spawned
		data.Rings = data.Rings - 1
		if data.Rings <= 0 then
			timer:Remove()
		end

	else
		data.Timer = data.Timer - 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.FireRingHelperUpdate, mod.Entities.FireRingHelper)



-- Smoke particles
---@param entity Entity
---@param offset Vector? Offsets the base spawn position from the spawner entity.
---@param radius number? The length of the radius to spawn in around the spawn position. Default is `0`.
---@param scale Vector? A Vector where `X` is the minimum scale and `Y` is the maximum scale. Can be left out to always be `1`.
---@param color Color?
---@param depthOffset number? Depth offset compared to the entity's depth offset. Default is `-100`.
---@param newSprite string? The path to the new spritesheet. `gfx/` and `.png` are not needed!
---@return EntityEffect smoke
function ReworkedFoes:SmokeParticles(entity, offset, radius, scale, color, depthOffset, newSprite)
	local smoke = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 0, entity.Position, mod:RandomVector(), entity):ToEffect()
	smoke.DepthOffset = entity.DepthOffset + (depthOffset or -100)

	-- Set the offset
	local radiusOffset = smoke.Velocity:Resized(radius or 0)
	smoke.SpriteOffset = (offset or Vector.Zero) + radiusOffset

	-- Set the scale
	if scale then
		local scaler = math.random(scale.X, scale.Y) / 100
		smoke.SpriteScale = Vector.One * scaler
	end

	local sprite = smoke:GetSprite()
	sprite.PlaybackSpeed = 0.4

	-- Set the color and sprites
	sprite.Color = color or Color.Default

	if newSprite then
		sprite:ReplaceSpritesheet(0, "gfx/" .. newSprite .. ".png")
		sprite:LoadGraphics()
	end

	smoke:Update()
	return smoke
end



-- Throw a Dip, similar to ThrowSpider
---@param position Vector
---@param spawner Entity
---@param targetPosition Vector The position to throw to.
---@param variant integer The variant of the Dip.
---@param yOffset number The height to throw the Dip from.
---@return EntityFamiliar | EntityNPC
function ReworkedFoes:ThrowDip(position, spawner, targetPosition, variant, yOffset)
	-- If spawner is friendly
	if spawner:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and spawner.SpawnerEntity and spawner.SpawnerEntity:ToPlayer() then
		local subtype = 0
		-- Corny
		if variant == 1 or variant == 3 then
			subtype = 2
		-- Brownie
		elseif variant == 2 then
			subtype = 20
		end

		return spawner.SpawnerEntity:ToPlayer():ThrowFriendlyDip(subtype, position, targetPosition)

	else
		local spider = EntityNPC.ThrowSpider(position, spawner, targetPosition, false, yOffset)
		spider:GetData().thrownDip = variant
		spider:SetSize(9, Vector.One, 12)

		-- Get the proper animatiom file
		local anm2 = "216.000_dip"
		if variant == 1 then
			anm2 = "216.001_corn"
		elseif variant == 2 then
			anm2 = "216.002_browniecorn"
		elseif variant == 3 then
			anm2 = "216.003_big corn"
		end

		local sprite = spider:GetSprite()
		sprite:Load("gfx/" .. anm2 .. ".anm2", true)
		sprite:Play("Move", true)

		spider:Update()
		return spider
	end
end

function mod:ThrownDipUpdate(entity)
	local data = entity:GetData()

	if data.thrownDip then
		mod:FlipTowardsMovement(entity, entity:GetSprite())

		if entity.State ~= NpcState.STATE_JUMP or entity:IsDead() then
			entity:Morph(EntityType.ENTITY_DIP, data.thrownDip, 0, -1)
			mod:PlaySound(entity, SoundEffect.SOUND_BABY_HURT)
			data.thrownDip = nil

			entity.State = NpcState.STATE_INIT
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

			if entity.Variant == 3 then
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
			else
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ThrownDipUpdate, EntityType.ENTITY_SPIDER)



-- Turn red poops in the room into regular ones
function ReworkedFoes:RemoveRedPoops()
	local room = Game():GetRoom()

	for i = 0, room:GetGridSize() do
		local grid = room:GetGridEntity(i)

		if grid ~= nil and grid:GetType() == GridEntityType.GRID_POOP and grid:GetVariant() == 1 then
			grid:SetVariant(0)
			grid:ToPoop().ReviveTimer = 0
			grid.State = 0

			-- Reset the sprite
			local sprite = grid:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/grid/grid_poop_" .. math.random(1, 3) .. ".png")
			sprite:LoadGraphics()
			sprite:Play("Appear", true)
		end
	end
end



-- One-time effect
function mod:OneTimeEffectUpdate(effect)
	if effect:GetSprite():IsFinished() then
		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.OneTimeEffectUpdate, mod.Entities.OneTimeEffect)