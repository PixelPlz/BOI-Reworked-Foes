local mod = ReworkedFoes



function mod:MembrainUpdate(entity)
	if entity.Variant < 2 then
		local sprite = entity:GetSprite()
		local params = ProjectileParams()

		-- For both
		params.Acceleration = 1.075
		params.FallingSpeedModifier = 1
		params.FallingAccelModifier = -0.1
		params.Scale = 1.4


		--[[ Membrain ]]--
		if entity.Variant == 0 then
			local data = entity:GetData()

			-- Shoot
			if sprite:IsEventTriggered("ShootNew") then
				params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
				params.ChangeFlags = ProjectileFlags.SMART
				params.Acceleration = 1.2
				params.ChangeTimeout = 9999
				params.CircleAngle = mod:Random(1) * mod:DegreesToRadians(30)

				data.stoppedProjectiles = {}
				for i, projectile in pairs(mod:FireProjectiles(entity, entity.Position, Vector(10, 6), 9, params)) do
					table.insert(data.stoppedProjectiles, projectile)
				end

				-- Effects
				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity)
				effect.SpriteScale = Vector(entity.Scale * 0.75, entity.Scale * 0.75)
				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.8)


			elseif data.stoppedProjectiles then
				-- Send the bullets at the player
				if sprite:IsEventTriggered("Activate") then
					for i, projectile in pairs(data.stoppedProjectiles) do
						projectile.ChangeTimeout = 0
						projectile.FallingAccel = -0.075
						projectile.Velocity = (entity:GetPlayerTarget().Position - projectile.Position):Resized(10)

						-- Effect
						local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 5, projectile.Position, Vector.Zero, entity):GetSprite()
						effect.Offset = Vector(projectile.PositionOffset.X, projectile.Height * 0.65)
						effect.Scale = Vector(0.75, 0.75)

						local c = mod.Colors.RagManPurple
						effect.Color = Color(c.R,c.G,c.B, 0.75, c.RO,c.GO,c.BO)
					end

					mod:PlaySound(nil, SoundEffect.SOUND_REDLIGHTNING_ZAP, 0.8)
				end


				-- Destroy the projectiles if it dies
				if entity:HasMortalDamage() then
					for i, projectile in pairs(data.stoppedProjectiles) do
						projectile:Kill()
					end
					data.stoppedProjectiles = nil
				end
			end



		--[[ Mama guts ]]--
		elseif entity.Variant == 1 and sprite:IsEventTriggered("Shoot") then
			params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
			params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
			params.ChangeTimeout = 90
			entity:FireProjectiles(entity.Position, Vector(8, 0), 8, params)

			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity)
			effect.SpriteScale = Vector(entity.Scale * 0.75, entity.Scale * 0.75)
		end
	end


	-- Make their hitboxes not stupidly small
	if entity.Variant <= 2 and entity.FrameCount <= 1 then
		entity:SetSize(28 * entity.Scale, Vector(1, 0.75), 12)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MembrainUpdate, EntityType.ENTITY_MEMBRAIN)