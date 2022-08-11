local mod = BetterMonsters
local game = Game()

local Settings = {
	MoveSpeed = 9,
	Cooldown = 15,
	MoveTime = 20
}



function mod:dartFlyInit(entity)
	entity:GetSprite().Offset = Vector(0, -16)
	entity.ProjectileCooldown = Settings.Cooldown
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.dartFlyInit, EntityType.ENTITY_DART_FLY)

function mod:dartFlyUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()

	-- Idle
	if entity.State == NpcState.STATE_MOVE then
		entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
		if not sprite:IsPlaying("Fly") then
			sprite:Play("Fly", true)
		end
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
			entity.V1 = (target.Position - entity.Position):Normalized() * Settings.MoveSpeed
		end

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

		else
			entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
			sprite.Rotation = (target.Position - entity.Position):GetAngleDegrees() - 90
		end
	end


	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.dartFlyUpdate, EntityType.ENTITY_DART_FLY)