local mod = BetterMonsters

local Settings = {
	FeatherShotSpeed = 10,
	PushBackSpeed = 20,
	LightShotSpeed = 11,
}



function mod:angelicBabyInit(entity)
	if entity.Variant == 1 and entity.SubType == 0 and entity.SpawnerType == EntityType.ENTITY_GABRIEL then
		if entity.SpawnerVariant == 1 then
			entity:Morph(EntityType.ENTITY_IMP, 0, 0, entity:GetChampionColorIdx())
		else
			entity:Morph(entity.Type, 1, 1, entity:GetChampionColorIdx())
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.angelicBabyInit, EntityType.ENTITY_BABY)

function mod:angelicBabyUpdate(entity)
	if entity.Variant == 1 and entity.SubType == 0 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()


		if sprite:IsEventTriggered("Attack") then
			entity.Velocity = (entity.Position - target.Position):Normalized() * Settings.PushBackSpeed
			entity:PlaySound(SoundEffect.SOUND_CUTE_GRUNT, 1, 0, false, 1.05)
			SFXManager():Play(SoundEffect.SOUND_ANGEL_WING, 1.2)

			-- Helix feather shots
			local params = ProjectileParams()
			params.Variant = IRFentities.featherProjectile
			params.FallingAccelModifier = -0.15
			params.ChangeTimeout = 21
			params.CurvingStrength = 0.0075

			params.BulletFlags = (ProjectileFlags.CURVE_LEFT | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.NO_WALL_COLLIDE)
			params.ChangeFlags = (ProjectileFlags.CURVE_RIGHT | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.NO_WALL_COLLIDE)
			entity:FireProjectiles(entity.Position, Vector.FromAngle((target.Position - entity.Position):GetAngleDegrees() + 45) * Settings.FeatherShotSpeed, 0, params)
			
			params.BulletFlags = (ProjectileFlags.CURVE_RIGHT | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.NO_WALL_COLLIDE)
			params.ChangeFlags = (ProjectileFlags.CURVE_LEFT | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.NO_WALL_COLLIDE)
			entity:FireProjectiles(entity.Position, Vector.FromAngle((target.Position - entity.Position):GetAngleDegrees() - 45) * Settings.FeatherShotSpeed, 0, params)


		elseif sprite:IsEventTriggered("Jump") then
			SFXManager():Play(SoundEffect.SOUND_HELL_PORTAL2, 0.8)
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, entity.TargetPosition, Vector.Zero, entity).DepthOffset = entity.DepthOffset - 10
		end


		if sprite:IsPlaying("Vanish2") then
			entity.Velocity = Vector.Zero

			if sprite:GetFrame() == 2 then
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_HUSH
				params.Color = Color(1,1,1, 1, 0.25,0.25,0.25)
				params.FallingAccelModifier = -0.15
				params.BulletFlags = ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT
				params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
				params.ChangeTimeout = 12

				entity:FireProjectiles(entity.Position, Vector(Settings.LightShotSpeed, 0), 6, params)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.angelicBabyUpdate, EntityType.ENTITY_BABY)