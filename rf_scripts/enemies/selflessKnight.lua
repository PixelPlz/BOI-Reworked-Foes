local mod = ReworkedFoes

local Settings = {
	MoveSpeed = 4,
	ChargeSpeed = 1.25,
	ShotSpeed = 9,
	TearCooldown = 30 * 2,
	InitialCooldown = 30 / 2,
}



function mod:SelflessKnightUpdate(entity)
	if entity.Variant == 1 then
		-- Idle
		if entity.State == NpcState.STATE_MOVE then
			local speed = math.min(entity.Velocity:Length(), Settings.MoveSpeed)
			entity.Velocity = entity.Velocity:Resized(speed)

			-- Reset charge timer
			if entity.StateFrame > 0 then
				entity.StateFrame = 0
			end


		-- Charging
		elseif entity.State == NpcState.STATE_ATTACK then
			-- Reduced charge speed + initial tear cooldown
			if entity.StateFrame == 0 then
				entity.TargetPosition = entity.TargetPosition:Resized(Settings.ChargeSpeed)
				entity.ProjectileCooldown = Settings.InitialCooldown
			end

			entity.StateFrame = entity.StateFrame + 1


			-- Shoot
			if entity.ProjectileCooldown <= 0 then
				entity.ProjectileCooldown = Settings.TearCooldown

				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_TEAR
				entity:FireProjectiles(entity.Position, -entity.Velocity:Resized(Settings.ShotSpeed), 0, params)

				-- Effects
				local offset = Vector(0, -16) + -entity.Velocity:Resized(8)
				mod:ShootEffect(entity, 5, offset, mod.Colors.TearEffect, 0.65, entity.TargetPosition.Y >= 0)
				mod:PlaySound(nil, SoundEffect.SOUND_TEARS_FIRE, 0.8)

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.SelflessKnightUpdate, EntityType.ENTITY_KNIGHT)