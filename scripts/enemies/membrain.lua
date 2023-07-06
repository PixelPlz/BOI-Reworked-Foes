local mod = BetterMonsters



function mod:membrainUpdate(entity)
	if entity.Variant < 2 then
		local sprite = entity:GetSprite()
		local params = ProjectileParams()

		-- For both
		params.Acceleration = 1.075
		params.FallingSpeedModifier = 1
		params.FallingAccelModifier = -0.1
		params.Scale = 1.4


		-- Membrain
		if entity.Variant == 0 then
			if sprite:IsEventTriggered("ShootNew") then
				params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.CHANGE_VELOCITY_AFTER_TIMEOUT)
				params.ChangeFlags = (ProjectileFlags.ACCELERATE_TO_POSITION | ProjectileFlags.SMART | ProjectileFlags.DECELERATE)
				params.ChangeTimeout = 16
				params.ChangeVelocity = 0

				entity:FireProjectiles(entity.Position, Vector(8, 0), 8, params)
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity).SpriteScale = Vector(entity.Scale * 0.75, entity.Scale * 0.75)
				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.75)

			elseif sprite:IsEventTriggered("Activate") then
				mod:PlaySound(nil, SoundEffect.SOUND_REDLIGHTNING_ZAP, 0.75)
			end


		-- Mama guts
		elseif entity.Variant == 1 and sprite:IsEventTriggered("Shoot") then
			params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
			params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
			params.ChangeTimeout = 90

			entity:FireProjectiles(entity.Position, Vector(8, 0), 8, params)
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity).SpriteScale = Vector(entity.Scale * 0.75, entity.Scale * 0.75)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.membrainUpdate, EntityType.ENTITY_MEMBRAIN)

function mod:membrainBulletUpdate(entity)
	if entity.SpawnerType == EntityType.ENTITY_MEMBRAIN and entity.SpawnerVariant == 0 then
		if not entity.SpawnerEntity then
			entity:Die()

		else
			-- Change color
			if entity.FrameCount == 15 then
				entity:SetColor(Color(0.5,0.5,0.7, 1, 0.3,0.3,0.6), 5, 1, true, false)

			-- Move towards target
			elseif entity.FrameCount < 50 then
				entity.TargetPosition = entity.SpawnerEntity:ToNPC():GetPlayerTarget().Position

			-- Disappear
			elseif entity.FrameCount > 60 then
				entity:Die()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.membrainBulletUpdate, ProjectileVariant.PROJECTILE_NORMAL)