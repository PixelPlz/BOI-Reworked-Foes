local mod = ReworkedFoes



--[[ General functions ]]--
-- Lerp
function mod:Lerp(first, second, percent)
	return (first + (second - first) * percent)
end

-- Lerp to Vector.Zero
function mod:StopLerp(vector)
	return mod:Lerp(vector, Vector.Zero, 0.25)
end


-- Get sign from 1 or 0 / true or false
function mod:GetSign(value)
	if (type(value) == "number"  and value == 1)
	or (type(value) == "boolean" and value == true) then
		return 1
	else
		return -1
	end
end


-- Round a number up or down based on its decimals
function mod:RoundNumber(number)
	if number % 1 >= 0.5 then
		return math.ceil(number)
	else
		return math.floor(number)
	end
end


-- Clamp a number
function mod:ClampNumber(number, min, max)
	return math.min( math.max(number, min), max)
end

-- Clamp a vector
function mod:ClampVector(vector, clampDegrees)
	local length = vector:Length()
	local timesClampDegree = vector:GetAngleDegrees() / clampDegrees
	timesClampDegree = mod:RoundNumber(timesClampDegree)
	return Vector.FromAngle(clampDegrees * timesClampDegree):Resized(length)
end


-- Convert degrees to radians
function mod:DegreesToRadians(degrees)
	return degrees * math.pi / 180
end


-- Align a position to the grid
function mod:GridAlignedPosition(position)
	local room = Game():GetRoom()
	return room:GetGridPosition(room:GetGridIndex(position))
end


-- Better shoot function
function mod:FireProjectiles(entity, from, velocity, shootType, params, trailColor)
	-- Start recording projectiles
	mod.RecordedProjectiles = {}
    mod.RecordProjectiles = true

	-- Shoot projectiles
	entity:FireProjectiles(from, velocity, shootType, params or ProjectileParams())

	-- Stop recording
	mod.RecordProjectiles = false

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
function mod:PlaySound(entity, id, volume, pitch, cooldown, loop, pan)
	volume = volume or 1
	pitch = pitch or 1
	cooldown = cooldown or 0
	pan = pan or 0

	if entity then
		entity:ToNPC():PlaySound(id, volume, cooldown, loop, pitch)
	else
		SFXManager():Play(id, volume, cooldown, loop, pitch, pan)
	end
end


-- Extended color constructor
function mod:ColorEx(rgb, colorize, tint)
	local color = Color(rgb.R or rgb[1], rgb.G or rgb[2], rgb.B or rgb[3],   rgb.A or rgb[4],   rgb.RO or rgb[5], rgb.GO or rgb[6], rgb.BO or rgb[7])
	if colorize then
		color:SetColorize(colorize.RC or colorize[1], colorize.GC or colorize[2], colorize.BC or colorize[3],   colorize.AC or colorize[4])
	end
	if tint then
		color:SetTint(tint.RT or tint[1], tint.GT or tint[2], tint.BT or tint[3],   tint.AT or tint[4])
	end
	return color
end



--[[ Random functions ]]--
-- Replaces math.random 
function mod:Random(min, max, rng)
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
function mod:RandomVector(length)
	local vector = Vector.FromAngle(mod:Random(359))
	if length then
		vector = vector:Resized(length)
	end
	return vector
end


-- Get a random sign
function mod:RandomSign()
	if mod:Random(1) == 0 then
		return -1
	end
	return 1
end


-- Get a random index from a table
function mod:RandomIndex(fromTable)
	return fromTable[mod:Random(1, #fromTable)]
end



--[[ Sprite functions ]]--
-- Looping animation
function mod:LoopingAnim(sprite, anim, dontReset)
	if not sprite:IsPlaying(anim) then
		if dontReset == true then
			sprite:SetAnimation(anim, false)
		else
			sprite:Play(anim, true)
		end
	end
end

-- Looping overlay
function mod:LoopingOverlay(sprite, anim, priority)
	if not sprite:IsOverlayPlaying(anim) then
		if priority then
			sprite:SetOverlayRenderPriority(priority)
		end
		sprite:PlayOverlay(anim, true)
	end
end


-- Flip towards the entity's movement
function mod:FlipTowardsMovement(entity, sprite, otherWay)
	if (otherWay ~= true and entity.Velocity.X < 0)
	or (otherWay == true and entity.Velocity.X > 0) then
		sprite.FlipX = true
	else
		sprite.FlipX = false
	end
end

-- Flip towards the entity's target
function mod:FlipTowardsTarget(entity, sprite, otherWay)
	local target = entity:GetPlayerTarget()

	if (otherWay ~= true and target.Position.X < entity.Position.X)
	or (otherWay == true and target.Position.X > entity.Position.X) then
		sprite.FlipX = true
	else
		sprite.FlipX = false
	end
end


-- Get direction string from angle degrees
function mod:GetDirectionString(angleDegrees, noSeparateHorizontal, useSide, noSeparateVertical)
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

function mod:GetDirectionStringEX(angleDegrees) -- This sucks
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



--[[ Movement presets ]]--
-- Wander around randomly
function mod:WanderAround(entity, speed)
	-- Chase if charmed of friendly / Run away if feared
	if entity:HasEntityFlags(EntityFlag.FLAG_CHARM) or entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
	or entity:HasEntityFlags(EntityFlag.FLAG_FEAR)  or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
		mod:ChasePlayer(entity, speed)
	else
		entity.Pathfinder:MoveRandomlyBoss(false)
		entity.Velocity = entity.Velocity:Resized(speed)
	end
end


-- Chase player
function mod:ChasePlayer(entity, speed, canFly)
	local target = entity:GetPlayerTarget()

	-- Reverse movement if feared
	if entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
		speed = -speed
	end

	-- Move randomly if confused
	if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
		mod:WanderAround(entity, speed)

	else
		-- If there is a path to the player
		if entity.Pathfinder:HasPathToPos(target.Position) or canFly == true then
			-- If there is a direct line to the player
			if Game():GetRoom():CheckLine(entity.Position, target.Position, LineCheckMode.RAYCAST) or canFly == true then
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


-- Grid aligned random movement
function mod:MoveRandomGridAligned(entity, speed, canFly, dontDoubleBack)
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
	local fearedOrCharmed = entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) or entity:HasEntityFlags(EntityFlag.FLAG_CHARM) or entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)


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

			if fearedOrCharmed == true then
				for i, direction in pairs(validDirections) do
					local currentChosenPosition = gridAlignedPos + (Vector.FromAngle(chosenDirection * 90) * 40)
					local checkPos = gridAlignedPos + (Vector.FromAngle(direction * 90) * 40)
					local nearestPlayer = Game():GetNearestPlayer(entity.Position).Position

					if ((entity:HasEntityFlags(EntityFlag.FLAG_FEAR)  or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK))   and checkPos:Distance(nearestPlayer) > currentChosenPosition:Distance(nearestPlayer))
					or ((entity:HasEntityFlags(EntityFlag.FLAG_CHARM) or entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)) and checkPos:Distance(nearestPlayer) < currentChosenPosition:Distance(nearestPlayer)) then
						chosenDirection = direction
					end
				end
			end

			data.movementDirection = chosenDirection
		end

		data.moveTimer = mod:Random(1, 4)
		data.currentIndex = room:GetGridIndex(entity.Position)


	-- Move in the selected direction
	else
		entity.Velocity = mod:Lerp(entity.Velocity, ((gridAlignedPos + Vector.FromAngle(data.movementDirection * 90) * 40) - entity.Position):Resized(speed), 0.35)

		if room:GetGridIndex(entity.Position) ~= data.currentIndex then
			-- Feared and charmed enemies always try to change directions as soon as they can
			if fearedOrCharmed == true then
				data.moveTimer = 0
			else
				data.moveTimer = data.moveTimer - 1
			end
		end
		data.currentIndex = room:GetGridIndex(entity.Position)
	end
end


-- Bounce around diagonally
function mod:MoveDiagonally(entity, speed, lerpStep)
	-- Move randomly if confused
	if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
		mod:WanderAround(entity, speed)


	-- Run away if feared
	elseif entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
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
function mod:AvoidPlayer(entity, radius, wanderSpeed, runSpeed, canFly)
	-- Get nearest player
	local nearest = Game():GetNearestPlayer(entity.Position)


	-- Chase if charmed of friendly
	if entity:HasEntityFlags(EntityFlag.FLAG_CHARM) or entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
		mod:ChasePlayer(entity, wanderSpeed + (runSpeed - wanderSpeed) / 2)


	-- Run away if there are players in radius
	elseif nearest.Position:Distance(entity.Position) <= radius and not entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
		-- Get target position
		local room = Game():GetRoom()
		local vector = (entity.Position - nearest.Position):Normalized()
		local targetPos = entity.Position + vector:Resized(radius)


		-- Go around obstacles
		if entity.Pathfinder:HasPathToPos(targetPos) or (canFly == true and room:IsPositionInRoom(targetPos, 0)) then
			if room:CheckLine(entity.Position, targetPos, LineCheckMode.ENTITY) or canFly == true then
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
function mod:OrbitParent(entity, parent, speed, distance, group)
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
			others = Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, true)
		end


		-- Get orbit index and leader
		local siblingCount = 0
		local leader = nil

		for i, sibling in pairs(others) do
			-- Orbiting the same parent
			if sibling:HasCommonParentWithEntity(entity) then
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


-- Check if target is aligned cardinally
-- 0 - Allow all directions
-- 1 - Only allow the direction I'm facing
-- 2 - Allow the direction I'm facing + the directions to my side
function mod:CheckCardinalAlignment(entity, sideRange, forwardRange, lineCheckMode, directionCheckMode, facingAngle)
	local target = entity:GetPlayerTarget()

	-- Don't check if there are obstacles in the way
	if Game():GetRoom():CheckLine(entity.Position, target.Position, lineCheckMode, 0, false, false) then
		for i = 0, 1 do
			-- Get the position to check
			local lineEnd = Vector(target.Position.X, entity.Position.Y)
			if i == 1 then
				lineEnd = Vector(entity.Position.X, target.Position.Y)
			end

			-- Check if the distances are within range
			if (target.Position - lineEnd):Length() <= sideRange and (entity.Position - lineEnd):Length() <= forwardRange then
				local targetAngle = (lineEnd - entity.Position):GetAngleDegrees()
				local facingAngle = facingAngle or entity.Velocity:GetAngleDegrees()

				if not directionCheckMode or directionCheckMode == 0 -- Allow all directions
				or (directionCheckMode == 1 and targetAngle == facingAngle) -- Only allow the direction I'm facing
				or (directionCheckMode == 2 and math.abs(targetAngle - facingAngle) <= 90) then -- Allow the direction I'm facing + the directions to my side
					return targetAngle
				end
			end
		end
	end

	return false
end



--[[ Spawning helper functions ]]--
-- Creep
function mod:QuickCreep(type, spawner, position, scale, timeout)
	local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, type, 0, position, Vector.Zero, spawner):ToEffect()
	creep.SpriteScale = Vector(scale or 1, scale or 1)

	if timeout then
		creep:SetTimeout(timeout)
	end

	creep:Update()
	return creep
end


-- Shooting effect
function mod:ShootEffect(entity, subtype, offset, color, scale, behind)
	local entityScale = entity:ToNPC() and entity:ToNPC().Scale or 1
	offset = offset and entityScale * offset or Vector.Zero
	scale = scale and entityScale * scale or 1

	local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, subtype, entity.Position, Vector.Zero, entity):ToEffect()
	local sprite = effect:GetSprite()

	effect:FollowParent(entity)
	sprite.Offset = offset
	sprite.Color = color or Color.Default
	effect.SpriteScale = Vector(scale, scale)

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


-- Tracer
function mod:QuickTracer(spawner, angle, offset, fadeIn, fadeOut, width, color)
	local tracer = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GENERIC_TRACER, 0, spawner.Position, Vector.Zero, spawner):ToEffect()
	tracer.TargetPosition = Vector.FromAngle(angle)

	tracer:FollowParent(spawner)
	tracer.ParentOffset = offset

	tracer.LifeSpan = fadeIn or 1
	tracer.Timeout = fadeOut or 1

	tracer.SpriteScale = Vector(width or 1, 0)
	tracer:GetSprite().Color = color or Color(1,0,0, 0.25)

	tracer:Update()
	return tracer
end


-- Sprite trail
function mod:QuickTrail(parent, length, color, width)
	if not parent:GetData().spriteTrail
	and (parent.Type ~= EntityType.ENTITY_PROJECTILE or not BulletTrails) then -- Don't spawn one for projectiles if Enemy Bullet Trails is enabled
		local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SPRITE_TRAIL, 0, parent.Position, Vector(0, parent.Height or parent.PositionOffset.Y), parent):ToEffect()
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


-- Smoke particles
function mod:SmokeParticles(entity, offset, radius, scale, color, newSprite)
	if entity:IsFrame(2, 0) then
		for i = 1, 4 do
			local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 0, entity.Position, mod:RandomVector(), entity):ToEffect()
			local sprite = trail:GetSprite()

			trail.DepthOffset = entity.DepthOffset - 50
			sprite.PlaybackSpeed = 0.5

			trail.SpriteOffset = offset + (trail.Velocity * radius)

			if scale then
				local scaler = math.random(scale.X, scale.Y) / 100
				trail.SpriteScale = Vector(scaler, scaler)
			end

			sprite.Color = color or Color.Default

			if newSprite then
				sprite:ReplaceSpritesheet(0, "gfx/" .. newSprite .. ".png")
				sprite:LoadGraphics()
			end

			trail:Update()
		end
	end
end


-- Ember particles
function mod:EmberParticles(entity, offset, radiusModifier, color)
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


-- Cord
function mod:QuickCord(parent, child, anm2)
	local cord = Isaac.Spawn(EntityType.ENTITY_EVIS, 10, 0, parent.Position, Vector.Zero, parent):ToNPC()
	cord.Parent = parent
	cord.Target = child
	parent.Child = cord
	cord.DepthOffset = child.DepthOffset - 150

	if anm2 then
		cord:GetSprite():Load("gfx/" .. anm2 .. ".anm2", true)
	end

	return cord
end


-- Throw Dip
function mod:ThrowDip(position, spawner, targetPosition, variant, yOffset)
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
		spawner.SpawnerEntity:ToPlayer():ThrowFriendlyDip(subtype, position, targetPosition)

	else
		local spider = EntityNPC.ThrowSpider(position, spawner, targetPosition, false, yOffset)
		spider:GetData().thrownDip = variant
		spider:SetSize(9, Vector(1, 1), 12)

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
	end
end


-- Fire ring attack
local fireRingHelperVariant = Isaac.GetEntityVariantByName("Fire Ring Helper")

function mod:CreateFireRing(entity, subtype, rings, delay, distance, startIndex, startDistance)
	local pos = entity and entity.Position or Game():GetRoom():GetCenterPos()
	local timer = Isaac.Spawn(EntityType.ENTITY_EFFECT, fireRingHelperVariant, subtype, pos, Vector.Zero, entity):ToEffect()
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
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.FireRingHelperInit, fireRingHelperVariant)

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

		timer.LifeSpan = timer.LifeSpan + 1
		timer.Timeout = timer.Timeout + 1 -- Always starts at 0
		timer.Scale = math.max(0.1, timer.Scale - timer.Timeout / 10)

		-- Remove self after all rings have spawned
		data.Timer = data.Delay
		data.Rings = data.Rings - 1
		if data.Rings <= 0 then
			timer:Remove()
		end

	else
		data.Timer = data.Timer - 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.FireRingHelperUpdate, fireRingHelperVariant)



--[[ Misc. functions ]]--
-- Turn red poops in the room into regular ones
function mod:RemoveRedPoops()
	local room = Game():GetRoom()

	for i = 0, room:GetGridSize() do
		local grid = room:GetGridEntity(i)
		if grid ~= nil and grid:GetType() == GridEntityType.GRID_POOP and grid:GetVariant() == 1 then
			grid:SetVariant(0)
			grid:ToPoop().ReviveTimer = 0
			grid.State = 0

			local sprite = grid:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/grid/grid_poop_" .. math.random(1, 3) .. ".png")
			sprite:LoadGraphics()
			sprite:Play("Appear", true)
		end
	end
end


-- Revelations compatibility check for minibosses
function mod:CheckForRev()
	if REVEL and REVEL.IsRevelStage(true) then
		return true
	else
		return false
	end
end

function mod:CheckValidMiniboss(entity)
	if mod:CheckForRev() == false and ((entity.Variant == 0 and entity.SubType <= 1) or entity.Variant == 1) then
		return true
	end
	return false
end