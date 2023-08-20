local mod = BetterMonsters



function mod:overwriteRetributionDeathEffect(entity)
	if Retribution and entity.Variant == 1873 and entity:IsDead() then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.overwriteRetributionDeathEffect, EntityType.ENTITY_MAGGOT)
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.overwriteRetributionDeathEffect, EntityType.ENTITY_SPITTY)
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.overwriteRetributionDeathEffect, EntityType.ENTITY_CONJOINED_SPITTY)



function mod:drownedMaggotDeath(entity)
	if Retribution and entity.Variant == 1873 then
		local params = ProjectileParams()
		params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
		params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
		params.ChangeTimeout = 90

		params.Acceleration = 1.1
		params.FallingSpeedModifier = 1
		params.FallingAccelModifier = -0.2
		params.Variant = ProjectileVariant.PROJECTILE_TEAR
		params.HeightModifier = 18

		for i = 1, 6 do
			params.Scale = 1 + (mod:Random(5) * 0.1)
			mod:FireProjectiles(entity, entity.Position, mod:RandomVector(mod:Random(4, 6)), 0, params).CollisionDamage = 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.drownedMaggotDeath, EntityType.ENTITY_MAGGOT)