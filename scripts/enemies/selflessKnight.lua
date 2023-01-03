local mod = BetterMonsters

local Settings = {
	SpeedMultiplier = 0.925,
	Cooldown = 50,
	ShotSpeed = 9
}



function mod:selflessKnightUpdate(entity)
	if entity.Variant == 1 then
		entity.Velocity = entity.Velocity * Settings.SpeedMultiplier

		if entity.ProjectileCooldown <= 0 then
			if entity.State == NpcState.STATE_ATTACK and entity.FrameCount > 30 and not entity:IsDead() then
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_TEAR
				params.FallingAccelModifier = 0.175

				entity:FireProjectiles(entity.Position, -entity.Velocity:Normalized() * Settings.ShotSpeed, 0, params)
				entity.ProjectileCooldown = Settings.Cooldown
				SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0.75)
			end

		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.selflessKnightUpdate, EntityType.ENTITY_KNIGHT)