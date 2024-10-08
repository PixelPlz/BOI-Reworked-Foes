local mod = ReworkedFoes

local Settings = {
	MoveSpeed = 8.5,
	Cooldown = {15, 25},
	MoveTime = 15,
}



function mod:DartFlyInit(entity)
	entity.PositionOffset = Vector(0, -16)
	entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
	entity.V2 = Vector(0, 1)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.DartFlyInit, EntityType.ENTITY_DART_FLY)

function mod:DartFlyUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()

	sprite.FlipX = false -- Fix for FF Honeydrop spawns

	-- Face the target
	local function faceTarget()
		entity.V1 = (target.Position - entity.Position):Normalized()
		entity.V2 = mod:Lerp(entity.V2, entity.V1, 0.15)
		sprite.Rotation = entity.V2:GetAngleDegrees() - 90
	end


	-- Idle
	if entity.State == NpcState.STATE_MOVE then
		entity.Velocity = mod:StopLerp(entity.Velocity)
		mod:LoopingAnim(sprite, "Fly")
		faceTarget()

		if entity.ProjectileCooldown <= 0 then
			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Dash", true)
			entity.ProjectileCooldown = Settings.MoveTime
		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end


	-- Dash
	elseif entity.State == NpcState.STATE_ATTACK then
		if sprite:IsEventTriggered("Dash") then
			entity.Velocity = entity.V2:Resized(Settings.MoveSpeed)
		end

		-- Moving
		if sprite:WasEventTriggered("Dash") then
			entity.Velocity = mod:Lerp(entity.Velocity, entity.V2:Resized(Settings.MoveSpeed), 0.25)
			sprite.Rotation = entity.Velocity:GetAngleDegrees() - 90

			-- Stop dashing
			if entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end

		-- Charge up
		else
			entity.Velocity = mod:StopLerp(entity.Velocity)
			faceTarget()
		end
	end


	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.DartFlyUpdate, EntityType.ENTITY_DART_FLY)