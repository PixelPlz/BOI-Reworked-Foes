local mod = BetterMonsters
local game = Game()



function mod:drownedBoomFlyUpdate(entity)
	if entity.Variant == 2 and entity:IsDead() then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.drownedBoomFlyUpdate, EntityType.ENTITY_BOOMFLY)

function mod:drownedBoomFlyDeath(entity)
	if entity.Variant == 0 and entity.SubType == 442 or entity.Variant == 2 then
		game:BombExplosionEffects(entity.Position, 100, TearFlags.TEAR_NORMAL, Color(1,1,1, 1, 0,0,0.1), entity, 1, true, true, DamageFlag.DAMAGE_EXPLOSION)
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

		entity:FireProjectiles(entity.Position, Vector(8, 0), 8, params)
		
		params.FallingAccelModifier = -0.2
		params.Scale = 1.75
		entity:FireProjectiles(entity.Position, Vector.Zero, 0, params)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.drownedBoomFlyDeath, EntityType.ENTITY_BOOMFLY)

function mod:dronwedEnemyProjectileUpdate(projectile)
	if ((projectile.SpawnerType == EntityType.ENTITY_CHARGER or projectile.SpawnerType == EntityType.ENTITY_HIVE) and projectile.SpawnerVariant == 1)
	or (projectile.SpawnerType == EntityType.ENTITY_BOOMFLY and projectile.SpawnerVariant == 2) then
		projectile.CollisionDamage = 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.dronwedEnemyProjectileUpdate, ProjectileVariant.PROJECTILE_TEAR)