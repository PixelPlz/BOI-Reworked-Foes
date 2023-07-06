local mod = BetterMonsters

local Settings = {
	SpeedMultiplier = 0.95,

	ChargeSpeed = 1.5,
	ChargeCooldown = 15,

	ShotSpeed = 9,
	TearCooldown = 45
}



function mod:selflessKnightUpdate(entity)
	if entity.Variant == 1 then
		entity.Velocity = entity.Velocity * Settings.SpeedMultiplier

		-- Idle
		if entity.State == NpcState.STATE_MOVE then
			-- Reset charge timer
			if entity.StateFrame > 0 then
				entity.StateFrame = 0
				entity.ProjectileCooldown = Settings.ChargeCooldown
			end


		-- Charging
		elseif entity.State == NpcState.STATE_ATTACK then
			if entity.StateFrame == 0 then
				entity.TargetPosition = entity.TargetPosition:Resized(Settings.ChargeSpeed)

			elseif entity.StateFrame > 5 then
				if entity.ProjectileCooldown <= 0 then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_TEAR
					params.FallingAccelModifier = 0.175
					entity:FireProjectiles(entity.Position, -entity.Velocity:Resized(Settings.ShotSpeed), 0, params)

					mod:PlaySound(nil, SoundEffect.SOUND_TEARS_FIRE, 0.8)
					mod:ShootEffect(entity, 5, Vector(0, -16) + -entity.Velocity:Resized(8), IRFcolors.TearEffect, 0.65, entity.TargetPosition.Y >= 0)
					entity.ProjectileCooldown = Settings.TearCooldown

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end
			end

			entity.StateFrame = entity.StateFrame + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.selflessKnightUpdate, EntityType.ENTITY_KNIGHT)