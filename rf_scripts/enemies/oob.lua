local mod = ReworkedFoes

local Settings = {
	BaseHP = 25,
	StageHP = 12.5,
	Cooldown = {60, 90},

	ChaseDistance = 5 * 40,
	MinMoveSpeed = 1,
	MaxMoveSpeed = 6,
	BlackMawSpeed = 5,

	ChargeSpeed = 22,
	WrapAroundMargin = 200,
}



function mod:OobInit(entity)
	mod:ChangeMaxHealth(entity, Settings.BaseHP, Settings.StageHP)
	entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.OobInit, EntityType.ENTITY_OOB)

function mod:OobUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()


	--[[ Idle ]]--
	if entity.State == NpcState.STATE_MOVE then
		-- Chase faster when in radius, move slowly otherwise
		local speed = Settings.MinMoveSpeed

		if target.Position:Distance(entity.Position) <= Settings.ChaseDistance then
			speed = Settings.MaxMoveSpeed
		end

		entity.V1 = mod:Lerp(entity.V1, Vector(speed, 0), 0.1)
		mod:ChasePlayer(entity, entity.V1.X, true)

		mod:LoopingAnim(sprite, "Walk")
		mod:FlipTowardsMovement(entity, sprite)

		-- Charge
		if entity.ProjectileCooldown <= 0 then
			entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])

			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Charge", true)
			entity.StateFrame = 0

		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end



	--[[ Charge attack ]]--
	elseif entity.State == NpcState.STATE_ATTACK then
		-- Start
		if entity.StateFrame == 0 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Get the charge direction
			if sprite:GetFrame() < 17 then
				mod:FlipTowardsTarget(entity, sprite)
			elseif sprite:GetFrame() == 17 then
				entity.TargetPosition = target.Position - entity.Position
			end

			if sprite:IsEventTriggered("Shoot") then
				entity.StateFrame = 1
				entity.Velocity = entity.TargetPosition:Resized(Settings.ChargeSpeed)
				entity.V2 = entity.Position

				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
				entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A)
			end


		-- Charging
		elseif entity.StateFrame >= 1 then
			entity.Velocity = mod:Lerp(entity.Velocity, entity.TargetPosition:Resized(Settings.ChargeSpeed), 0.25)
			mod:FlipTowardsMovement(entity, sprite)

			if not sprite:IsPlaying("Charge") then
				mod:LoopingAnim(sprite, "Charge Shake")
			end


			-- Stop charging when passing the starting point
			local room = Game():GetRoom()

			if entity.StateFrame >= 2 then
				local targetPos = entity.V2 - entity.Position
				local angleDifference = mod:GetAngleDifference(entity.Velocity, targetPos)

				if angleDifference >= 90 then
					entity.State = NpcState.STATE_MOVE
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
					entity.V1 = Vector.Zero
				end


			-- Wrap around
			elseif not room:IsPositionInRoom(entity.Position, -Settings.WrapAroundMargin) then
				local centerPos = room:GetCenterPos()

				-- FUCK L SHAPED ROOMS
				if room:IsLShapedRoom() then
					centerPos = Vector(room:GetGridWidth(), room:GetGridHeight()) * 40 / 2
				end

				local distance = centerPos:Distance(entity.Position) * 2
				entity.Position = entity.Position + -entity.TargetPosition:Resized(distance)
				entity.StateFrame = 2
			end
		end
	end


	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.OobUpdate, EntityType.ENTITY_OOB)




function mod:BlackMawInit(entity)
	mod:ChangeMaxHealth(entity, Settings.BaseHP, Settings.StageHP)
	entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BlackMawInit, EntityType.ENTITY_BLACK_MAW)

function mod:BlackMawUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()


	--[[ Idle ]]--
	if entity.State == NpcState.STATE_MOVE then
		mod:ChasePlayer(entity, Settings.BlackMawSpeed, true)
		mod:LoopingAnim(sprite, "Walk")
		mod:FlipTowardsMovement(entity, sprite)

		-- Charge
		if entity.ProjectileCooldown <= 0 then
			entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])

			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Charge", true)
			entity.StateFrame = 0

		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end



	--[[ Charge attack ]]--
	elseif entity.State == NpcState.STATE_ATTACK then
		-- Start
		if entity.StateFrame == 0 or entity.StateFrame == 2 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Get the charge direction
			if sprite:GetFrame() < 17 then
				mod:FlipTowardsTarget(entity, sprite)
			elseif sprite:GetFrame() == 17 then
				entity.TargetPosition = target.Position - entity.Position
				entity.V2 = target.Position
			end

			if sprite:IsFinished() then
				-- Only play the sound once
				if entity.StateFrame == 0 then
					mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A)
				end

				entity.StateFrame = entity.StateFrame + 1
				entity.Velocity = entity.TargetPosition:Resized(Settings.ChargeSpeed)

				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
				entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
			end


		-- Charging
		elseif entity.StateFrame == 1 or entity.StateFrame == 3 then
			entity.Velocity = mod:Lerp(entity.Velocity, entity.TargetPosition:Resized(Settings.ChargeSpeed), 0.25)
			mod:FlipTowardsMovement(entity, sprite)

			if not sprite:IsPlaying("Charge") then
				mod:LoopingAnim(sprite, "Charge Shake")
			end


			-- Stop charging when passing the target
			local room = Game():GetRoom()

			if entity.StateFrame == 3 then
				local targetPos = entity.V2 - entity.Position
				local angleDifference = mod:GetAngleDifference(entity.Velocity, targetPos)

				if angleDifference >= 90 then
					entity.State = NpcState.STATE_MOVE
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
					entity.V1 = Vector.Zero
				end


			-- Turn around
			elseif not room:IsPositionInRoom(entity.Position, -Settings.WrapAroundMargin) then
				entity.StateFrame = 2
				sprite:Play("Charge", true)
				sprite:SetFrame(10)
			end
		end



	--[[ Death attack ]]--
	elseif entity.State == NpcState.STATE_SPECIAL then
		-- Start
		if entity.StateFrame == 0 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Get the charge direction
			if sprite:GetFrame() < 17 then
				mod:FlipTowardsTarget(entity, sprite)
			elseif sprite:GetFrame() == 17 then
				entity.TargetPosition = target.Position - entity.Position
			end

			if sprite:IsFinished() then
				entity.StateFrame = 1
				entity.Velocity = entity.TargetPosition:Resized(Settings.ChargeSpeed)
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A)
			end


		-- Charging
		elseif entity.StateFrame == 1 or entity.StateFrame == 3 then
			entity.Velocity = mod:Lerp(entity.Velocity, entity.TargetPosition:Resized(Settings.ChargeSpeed), 0.25)
			mod:FlipTowardsMovement(entity, sprite)

			if not sprite:IsPlaying("Charge") then
				mod:LoopingAnim(sprite, "Charge Shake")
			end

			-- Only collide with walls if it's inside the room
			if Game():GetRoom():IsPositionInRoom(entity.Position, entity.Size) then
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
			end

			-- Explode on impact with a wall
			if entity:CollidesWithGrid() then
				entity:Kill()

				local color = mod:ColorEx({1,1,1, 1}, {0.25,0.25,0.25, 1})
				Game():BombExplosionEffects(entity.Position, 40, TearFlags.TEAR_NORMAL, color, entity, 1, true, true, DamageFlag.DAMAGE_EXPLOSION)

				local params = ProjectileParams()
				params.Scale = 1.5
				entity:FireProjectiles(entity.Position, Vector(10, 10), 9, params)
			end
		end
	end



	-- Do the suicide attack on death
	if entity:HasMortalDamage() and entity.State ~= NpcState.STATE_SPECIAL then
		entity.State = NpcState.STATE_SPECIAL
		entity.StateFrame = 0
		sprite:Play("Charge", true)

		entity.HitPoints = 1000
		entity.MaxHitPoints = 0

		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_4)
	end

	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.BlackMawUpdate, EntityType.ENTITY_BLACK_MAW)