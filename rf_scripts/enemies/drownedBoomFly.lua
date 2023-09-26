local mod = ReworkedFoes



function mod:OverwriteDrownedBoomFlyDeathEffect(entity)
	if (entity.Variant == 2 or (Retribution and entity.Variant == 1874)) and entity:IsDead() then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.OverwriteDrownedBoomFlyDeathEffect, EntityType.ENTITY_BOOMFLY)

function mod:DrownedBoomFlyDeath(entity)
	if entity.Variant == 2 or (Retribution and entity.Variant == 1874) then
		Game():BombExplosionEffects(entity.Position, 40, TearFlags.TEAR_NORMAL, Color(1,1,1, 1, 0,0,0.1), entity, 1, true, true, DamageFlag.DAMAGE_EXPLOSION)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_SPLASH, 0, entity.Position, Vector.Zero, entity)

		local params = ProjectileParams()
		params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
		params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
		params.ChangeTimeout = 90

		params.Acceleration = 1.09
		params.FallingSpeedModifier = 1
		params.FallingAccelModifier = -0.1
		params.Scale = 1.25
		params.Variant = ProjectileVariant.PROJECTILE_TEAR

		-- Outer projectiles
		-- Retribution Bloated Fly
		if entity.Variant == 1874 then
			local offset = mod:Random(10, 100) * 0.01

			params.CircleAngle = offset
			for i, projectile in pairs(mod:FireProjectiles(entity, entity.Position, Vector(6, 6), 9, params)) do
				projectile.CollisionDamage = 1
			end

			params.CircleAngle = offset + 0.5
			for i, projectile in pairs(mod:FireProjectiles(entity, entity.Position, Vector(10, 6), 9, params)) do
				projectile.CollisionDamage = 1
			end

		else
			for i, projectile in pairs(mod:FireProjectiles(entity, entity.Position, Vector(8, 0), 8, params)) do
				projectile.CollisionDamage = 1
			end
		end

		-- Center projectile
		params.FallingAccelModifier = -0.2
		params.Scale = 1.75
		entity:FireProjectiles(entity.Position, Vector.Zero, 0, params)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.DrownedBoomFlyDeath, EntityType.ENTITY_BOOMFLY)