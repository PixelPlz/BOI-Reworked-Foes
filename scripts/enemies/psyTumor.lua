local mod = BetterMonsters



function mod:psyTumorUpdate(entity)
	if entity:GetSprite():IsEventTriggered("NewShoot") then
		local params = ProjectileParams()
		params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.SMART)
		params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
		params.ChangeTimeout = 105

		params.Acceleration = 1.1
		params.FallingSpeedModifier = 1
		params.FallingAccelModifier = -0.1
		params.Scale = 1.5

		entity:FireProjectiles(entity.Position, Vector(5, 3), 9, params)
		entity:PlaySound(SoundEffect.SOUND_WHEEZY_COUGH, 1.1, 0, false, 1)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.psyTumorUpdate, EntityType.ENTITY_PSY_TUMOR)