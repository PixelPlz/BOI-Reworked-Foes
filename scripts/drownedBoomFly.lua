local mod = BetterMonsters
local game = Game()



function mod:drownedBoomFlyInit(entity)
	if entity.Variant == 2 then
		entity:Morph(EntityType.ENTITY_BOOMFLY, 0, 442, entity:GetChampionColorIdx())
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.drownedBoomFlyInit, EntityType.ENTITY_BOOMFLY)

function mod:drownedBoomFlyDeath(entity)
	if entity.Variant == 0 and entity.SubType == 442 then
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