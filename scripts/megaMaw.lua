local mod = BetterMonsters
local game = Game()

function mod:megaMawUpdate(entity)
	if entity.SubType == 1 then
		local sprite = entity:GetSprite()

		if sprite:IsFinished("FireRing") then
			entity.ProjectileCooldown = 30
		end
		
		if entity.ProjectileCooldown > 0 then
			entity.State = NpcState.STATE_IDLE
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end
		
		if sprite:IsEventTriggered("Shoot") then
			entity:PlaySound(SoundEffect.SOUND_GHOST_SHOOT, 1.25, 0, false, 1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.megaMawUpdate, EntityType.ENTITY_MEGA_MAW)

function mod:megaMawProjectileUpdate(projectile)
	if projectile.SpawnerEntity and (projectile.SpawnerEntity.Type == EntityType.ENTITY_MEGA_MAW or projectile.SpawnerEntity.Type == EntityType.ENTITY_GATE) and projectile.SpawnerEntity.SubType == 1 then
		projectile.CollisionDamage = 1
		projectile.Variant = ProjectileVariant.PROJECTILE_HUSH

		local sprite = projectile:GetSprite()
		sprite:Load("gfx/009.006_hush projectile.anm2", true)
		sprite:Play("RegularTear7", true)
		sprite.Color = brimstoneBulletColor
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.megaMawProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)

function mod:gateUpdate(entity)
	if entity.SubType == 1 and entity:GetSprite():IsEventTriggered("Shoot") then
		entity:PlaySound(SoundEffect.SOUND_GHOST_SHOOT, 1.25, 0, false, 1)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gateUpdate, EntityType.ENTITY_GATE)