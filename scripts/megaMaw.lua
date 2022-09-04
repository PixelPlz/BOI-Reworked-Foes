local mod = BetterMonsters
local game = Game()

function mod:megaMawUpdate(entity)
	if entity.SubType == 1 then
		if entity:GetSprite():IsFinished("FireRing") then
			entity.ProjectileCooldown = 30
		end
		
		if entity.ProjectileCooldown > 0 then
			entity.State = NpcState.STATE_IDLE
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end
		
		if entity:GetSprite():IsEventTriggered("Shoot") then
			entity:PlaySound(SoundEffect.SOUND_GHOST_SHOOT, 1.25, 0, false, 1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.megaMawUpdate, EntityType.ENTITY_MEGA_MAW)

function mod:megaMawProjectileUpdate(projectile)
	if projectile.SpawnerEntity and projectile.SpawnerEntity.Type == EntityType.ENTITY_MEGA_MAW and projectile.SpawnerEntity.SubType == 1 then -- Using the enum doesn't work?????
		projectile.CollisionDamage = 1
		projectile.Variant = ProjectileVariant.PROJECTILE_HUSH

		local sprite = projectile:GetSprite()
		sprite:Load("gfx/009.006_hush projectile.anm2", true)
		sprite:Play("RegularTear7", true)
		sprite.Color = brimstoneBulletColor
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.megaMawProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)
