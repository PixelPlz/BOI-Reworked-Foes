local mod = BetterMonsters
local game = Game()



-- Feather projectile
function mod:angelicFeatherUpdate(projectile)
	local sprite = projectile:GetSprite()

	if projectile.FrameCount <= 2 then
		sprite:Play("Move")

		if projectile.SubType == 1 then
			sprite.Color = Color(0.25,0.25,0.25, 1)
			projectile.SplatColor = tarBulletColor
		else
			projectile.SplatColor = Color(1,1,1, 1, 1,1,1)
		end
	end

	sprite.Rotation = projectile.Velocity:GetAngleDegrees()

	if projectile:IsDead() then
		local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BULLET_POOF, 0, projectile.Position, Vector.Zero, projectile):GetSprite()
		effect.Scale = Vector(0.75, 0.75)
		effect.Color = projectile.SplatColor
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.angelicFeatherUpdate, IRFentities.featherProjectile)

function mod:replaceAngleProjectile(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_URIEL or projectile.SpawnerType == EntityType.ENTITY_GABRIEL
	or (projectile.SpawnerType == EntityType.ENTITY_BABY and projectile.SpawnerVariant == 1 and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 1) then
		projectile.Variant = IRFentities.featherProjectile
		projectile:GetSprite():Load("gfx/feather_projectile.anm2", true)
		
		if (projectile.SpawnerType == EntityType.ENTITY_URIEL or projectile.SpawnerType == EntityType.ENTITY_GABRIEL) and projectile.SpawnerVariant == 1 then
			projectile.SubType = 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.replaceAngleProjectile, ProjectileVariant.PROJECTILE_NORMAL)



-- Cocoon projectile
function mod:cocoonInit(projectile)
	projectile:GetSprite():Play("Move")
	projectile:AddProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER)
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, mod.cocoonInit, IRFentities.cocoonProjectile)

function mod:cocoonUpdate(projectile)
	if projectile:IsDead() then
		SFXManager():Play(SoundEffect.SOUND_BOIL_HATCH)
		mod:QuickCreep(EffectVariant.CREEP_WHITE, projectile.SpawnerEntity, projectile.Position)
		Isaac.Spawn(EntityType.ENTITY_SWARM_SPIDER, 0, 0, projectile.Position, Vector.Zero, projectile.SpawnerEntity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SPIDER_EXPLOSION, 0, projectile.Position, Vector.Zero, projectile):GetSprite().Color = Color(1,1,1, 1, 1,1,1)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.cocoonUpdate, IRFentities.cocoonProjectile)



-- Fix some projectiles doing more damage than they should
function mod:dronwedEnemyProjectileUpdate(projectile)
	if ((projectile.SpawnerType == EntityType.ENTITY_CHARGER or projectile.SpawnerType == EntityType.ENTITY_HIVE) and projectile.SpawnerVariant == 1)
	or (projectile.SpawnerType == EntityType.ENTITY_BOOMFLY and projectile.SpawnerVariant == 2) then
		projectile.CollisionDamage = 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.dronwedEnemyProjectileUpdate, ProjectileVariant.PROJECTILE_TEAR)



-- Trailing projectile
function mod:trailingProjectileUpdate(projectile)
	if projectile:HasProjectileFlags(ProjectileFlags.BROCCOLI) then
		if projectile.FrameCount % 3 == 0 then
			local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HAEMO_TRAIL, 0, projectile.Position + projectile.Velocity, -projectile.Velocity:Normalized() * 2, projectile):ToEffect()
			local scaler = projectile.Scale * math.random(50, 70) / 100
			trail.SpriteScale = Vector(scaler, scaler)
			trail.SpriteOffset = Vector(0, projectile.Height + 6)
			trail.DepthOffset = -80

			if projectile.SpawnerType == EntityType.ENTITY_PORTAL and projectile.SpawnerVariant == 40 then
				trail:GetSprite().Color = portalBulletTrail
			end
			
			trail:Update()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.trailingProjectileUpdate, ProjectileVariant.PROJECTILE_HUSH)