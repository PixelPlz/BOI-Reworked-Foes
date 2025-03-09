local mod = ReworkedFoes



function mod:MembrainInit(entity)
	entity:SetSize(28, Vector(1, 0.75), 16)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MembrainInit, EntityType.ENTITY_MEMBRAIN)

function mod:MembrainUpdate(entity)
	if entity.Variant <= 1 then
		local sprite = entity:GetSprite()


		--[[ Membrain ]]--
		if entity.Variant == 0 then
			local data = entity:GetData()

			-- Shoot
			if sprite:IsEventTriggered("ShootNew") then
				local params = ProjectileParams()
				params.Scale = 1.5
				params.CircleAngle = mod:Random(1) * mod:DegreesToRadians(30)
				params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE)
				params.ChangeFlags = ProjectileFlags.SMART
				params.Acceleration = 1.25

				data.stoppedProjectiles = {}
				local projectiles = mod:FireProjectiles(entity, entity.Position, Vector(10, 6), 9, params)

				for i, projectile in pairs(projectiles) do
					projectile:GetData().RFLingering = 60
					table.insert(data.stoppedProjectiles, projectile)
				end

				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.8)


			-- Send the projectiles
			elseif sprite:IsEventTriggered("Activate") then
				for i, projectile in pairs(data.stoppedProjectiles) do
					projectile:GetData().RFLingering = nil
					projectile.ProjectileFlags = projectile.ChangeFlags
					--projectile.FallingAccel = -0.05
					projectile.Velocity = projectile.Velocity:Resized(10)

					-- Effect
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 5, projectile.Position, Vector.Zero, entity):GetSprite()
					effect.Offset = Vector(projectile.PositionOffset.X, projectile.Height * 0.65)
					effect.Scale = Vector(0.75, 0.75)

					local c = mod.Colors.RagManPurple
					effect.Color = Color(c.R,c.G,c.B, 0.75, c.RO,c.GO,c.BO)
				end

				mod:PlaySound(nil, SoundEffect.SOUND_REDLIGHTNING_ZAP, 0.8)
			end



		--[[ Mama guts ]]--
		elseif entity.Variant == 1 and sprite:IsEventTriggered("Shoot") then
			local params = ProjectileParams()
			params.Scale = 1.5
			params.CircleAngle = mod:DegreesToRadians(22.5)
			params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE)
			params.Acceleration = 1.075

			local projectiles = mod:FireProjectiles(entity, entity.Position, Vector(8, 8), 9, params)
			for i, projectile in pairs(projectiles) do
				projectile:GetData().RFLingering = 90
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MembrainUpdate, EntityType.ENTITY_MEMBRAIN)