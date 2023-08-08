local mod = BetterMonsters

local Settings = {
	MoveSpeed = 8,
	Cooldown = 16,
	MoveTime = 16
}



function mod:dartFlyInit(entity)
	entity.PositionOffset = Vector(0, -16)
	entity.ProjectileCooldown = Settings.Cooldown

	local sprite = entity:GetSprite()
	sprite.Rotation = 0
	sprite.FlipX = false -- Fix for FF Honeydrop spawns
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.dartFlyInit, EntityType.ENTITY_DART_FLY)

function mod:dartFlyUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()


	-- Idle
	if entity.State == NpcState.STATE_MOVE then
		entity.Velocity = mod:StopLerp(entity.Velocity)
		mod:LoopingAnim(sprite, "Fly")
		sprite.Rotation = (target.Position - entity.Position):GetAngleDegrees() - 90

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
			entity.I1 = 1
			entity.V1 = (target.Position - entity.Position):Resized(Settings.MoveSpeed)
		end

		-- Moving
		if entity.I1 == 1 then
			entity.Velocity = entity.V1
			sprite.Rotation = entity.Velocity:GetAngleDegrees() - 90

			if entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = Settings.Cooldown
				entity.I1 = 0
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end

		-- Charge up
		else
			entity.Velocity = mod:StopLerp(entity.Velocity)
			sprite.Rotation = (target.Position - entity.Position):GetAngleDegrees() - 90
		end
	end


	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.dartFlyUpdate, EntityType.ENTITY_DART_FLY)