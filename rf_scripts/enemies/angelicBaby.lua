local mod = ReworkedFoes

local Settings = {
	FeatherShotSpeed = 10,
	PushBackSpeed = 20,
	LightShotSpeed = 11,
}



function mod:AngelicBabyInit(entity)
	if entity.Variant == 1 and entity.SubType == 0 and entity.SpawnerType == EntityType.ENTITY_GABRIEL then
		if entity.SpawnerVariant == 1 then
			entity:Morph(EntityType.ENTITY_IMP, 0, 0, entity:GetChampionColorIdx())
		else
			entity:Morph(entity.Type, 1, 1, entity:GetChampionColorIdx())
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.AngelicBabyInit, EntityType.ENTITY_BABY)

function mod:AngelicBabyUpdate(entity)
	if entity.Variant == 1 and entity.SubType == 0 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()

		-- New projectile attack
		if sprite:IsEventTriggered("Attack") then
			entity.Velocity = (entity.Position - target.Position):Resized(Settings.PushBackSpeed)
			mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT, 1, 1.05)
			mod:PlaySound(nil, SoundEffect.SOUND_ANGEL_WING)

			-- Helix feather shots
			local params = ProjectileParams()
			params.Variant = mod.Entities.FeatherProjectile
			params.FallingAccelModifier = -0.15
			params.ChangeTimeout = 21
			params.CurvingStrength = 0.0075

			for i = -1, 1, 2 do
				local left = (ProjectileFlags.CURVE_LEFT | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.NO_WALL_COLLIDE)
				local right = (ProjectileFlags.CURVE_RIGHT | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.NO_WALL_COLLIDE)

				if i == -1 then
					params.BulletFlags = right
					params.ChangeFlags = left
				else
					params.BulletFlags = left
					params.ChangeFlags = right
				end

				entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Rotated(i * 45):Resized(Settings.FeatherShotSpeed), 0, params)
			end


		-- Crack the sky beam on teleport
		elseif sprite:IsEventTriggered("Jump") then
			mod:PlaySound(nil, SoundEffect.SOUND_HELL_PORTAL2, 0.8)
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, entity.TargetPosition, Vector.Zero, entity).DepthOffset = entity.DepthOffset - 10
		end

		-- Stop them from moving while teleporting
		if sprite:IsPlaying("Vanish2") then
			entity.Velocity = Vector.Zero
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.AngelicBabyUpdate, EntityType.ENTITY_BABY)