local mod = ReworkedFoes

local Settings = {
	LingerTime = 90,
}



function mod:OverwriteDrownedBoomFlyDeathEffect(entity)
	if (entity.Variant == 2 or (Retribution and entity.Variant == 1874)) and entity:IsDead() then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.OverwriteDrownedBoomFlyDeathEffect, EntityType.ENTITY_BOOMFLY)

function mod:DrownedBoomFlyDeath(entity)
	if entity.Variant == 2 or (Retribution and entity.Variant == 1874) then
		-- Explosion + effects
		Game():BombExplosionEffects(entity.Position, 40, TearFlags.TEAR_NORMAL, Color(1,1,1, 1, 0,0,0.1), entity, 1, true, true, DamageFlag.DAMAGE_EXPLOSION)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_SPLASH, 0, entity.Position, Vector.Zero, entity)


		-- Outer projectiles
		local params = ProjectileParams()
		params.Variant = ProjectileVariant.PROJECTILE_TEAR
		params.Scale = 1.25
		params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE)
		params.Acceleration = 1.08


		-- Retribution Bloated Fly
		if entity.Variant == 1874 then
			local offset = mod:DegreesToRadians(mod:Random(359))

			for i = 0, 1 do
				local speed = i == 1 and 10 or 6

				local circleOffset = i * mod:DegreesToRadians(30)
				params.CircleAngle = offset + circleOffset

				for j, projectile in pairs(mod:FireProjectiles(entity, entity.Position, Vector(speed, 6), 9, params)) do
					projectile:GetData().RFLingering = Settings.LingerTime
					projectile.CollisionDamage = 1
				end
			end

		-- Regular Drowned Fly
		else
			for i, projectile in pairs(mod:FireProjectiles(entity, entity.Position, Vector(7, 0), 8, params)) do
				projectile:GetData().RFLingering = Settings.LingerTime
				projectile.CollisionDamage = 1
			end
		end


		-- Center projectile
		params.Scale = 1.75
		mod:FireProjectiles(entity, entity.Position, Vector.Zero, 0, params):GetData().RFLingering = Settings.LingerTime
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.DrownedBoomFlyDeath, EntityType.ENTITY_BOOMFLY)