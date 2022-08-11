local mod = BetterMonsters
local game = Game()



function mod:dankSquirtUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()

		if (entity.State == NpcState.STATE_MOVE or (sprite:IsPlaying("Attack01") and sprite:GetFrame() > 35)) and entity:IsFrame(3, 0) then
			local params = ProjectileParams()
			params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
			params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
			params.ChangeTimeout = 45

			params.Acceleration = 1.1
			params.FallingSpeedModifier = 1
			params.FallingAccelModifier = -0.2
			params.Scale = 1 + (math.random(25, 40) * 0.01)
			params.HeightModifier = 19
			params.Color = tarBulletColor

			entity:FireProjectiles(entity.Position - entity.Velocity:Normalized(), -Vector.FromAngle(entity.Velocity:GetAngleDegrees() + math.random(-30, 30)) * 3, 0, params)
			entity:PlaySound(SoundEffect.SOUND_BOSS2_BUBBLES, 0.6, 0, false, 1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.dankSquirtUpdate, EntityType.ENTITY_SQUIRT)

-- Only spawn one clot on death
function mod:dankSquirtDeath(entity)
	if entity.Variant == 1 then
		for i, clots in ipairs(Isaac.GetRoomEntities()) do
			if clots.Type == EntityType.ENTITY_CLOTTY and clots.Variant == 1 and clots.SpawnerType == EntityType.ENTITY_SQUIRT and clots.SpawnerVariant == 1 then
				clots:Remove()
			end
		end

		Isaac.Spawn(EntityType.ENTITY_CLOTTY, 1, 0, entity.Position, Vector.Zero, entity)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_BLACK, 0, entity.Position, Vector.Zero, entity):ToEffect().Scale = 1.5
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.dankSquirtDeath, EntityType.ENTITY_SQUIRT)