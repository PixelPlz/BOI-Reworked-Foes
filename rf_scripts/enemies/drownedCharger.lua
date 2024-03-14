local mod = ReworkedFoes



function mod:DrownedChargerInit(entity)
	if entity.Variant == 1 and entity.SpawnerType == EntityType.ENTITY_HIVE then
		entity.State = NpcState.STATE_ATTACK
		mod:PlaySound(entity, SoundEffect.SOUND_MAGGOTCHARGE)

		local vector = (entity:GetPlayerTarget().Position - entity.Position):Normalized()
		entity.V1 = mod:ClampVector(vector, 90)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.DrownedChargerInit, EntityType.ENTITY_CHARGER)

function mod:DrownedChargerUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()

		-- Get multiplier
		entity.I2 = math.floor(entity.I1 / 20) + 1

		-- Get the proper animation to play
		local function getAnimation(prefix)
			local dir = mod:GetDirectionString(entity.V1:GetAngleDegrees(), true)
			local size = tostring(entity.I2)
			return prefix .. " " .. dir .. " " .. size
		end

		-- Function to start blowing
		local function startBlowing()
			entity.State = NpcState.STATE_ATTACK2
			sprite:Play(getAnimation("Blow"), true)
		end



		-- Do blowing attack
		if entity.State == NpcState.STATE_MOVE and entity.I1 > 0 then
			startBlowing()

		-- Charging
		elseif entity.State == NpcState.STATE_ATTACK then
			-- Custom animations
			mod:LoopingAnim(sprite, getAnimation("Attack"))

			-- Stop charging after a set amount of time
			if entity.I1 >= 75 then
				startBlowing()
			end

			-- Only do blowing attack in rooms with water
			if Game():GetRoom():HasWater() then
				entity.I1 = entity.I1 + 1
			end



		-- Blowing back
		elseif entity.State == NpcState.STATE_ATTACK2 then
			-- Start blowing
			if entity.ProjectileCooldown == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("BlowStart") then
					entity.ProjectileCooldown = 1
				end


			-- Shoot + push back
			elseif entity.ProjectileCooldown == 1 then
				entity.Velocity = -entity.V1:Resized(entity.I1 * 0.2)

				-- Get animation
				local anim = getAnimation("Blow")

				if not sprite:IsPlaying(anim) then
					sprite:Play(anim, true)
					sprite:SetFrame(8)
				end


				-- Projectiles
				if entity:IsFrame(math.max(1, 5 - math.floor(entity.I1 / 16)), 0) then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_TEAR
					params.Scale = (entity.I2 + 1) * 0.3
					params.HeightModifier = 18
					params.FallingAccelModifier = 0.5
					params.FallingSpeedModifier = -entity.I2
					mod:FireProjectiles(entity, entity.Position + entity.V1:Resized(6), entity.V1:Rotated(mod:Random(-10, 10)):Resized(8 + entity.I2 * 2), 0, params).CollisionDamage = 1

					-- Effects
					if entity:IsFrame(3, 0) then
						mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 0.5 + entity.I2 * 0.1)

						local offset = entity.V1:Resized(8 + entity.I2)
						local scale = 0.5 + entity.I2 * 0.2
						mod:ShootEffect(entity, 1, offset, mod.Colors.TearEffect, scale, entity.V1.Y < 0)
					end
				end


				-- Blow timer
				if entity.I1 <= 0 then
					entity.ProjectileCooldown = 2

				else
					entity.I1 = entity.I1 - 1
					-- Custom loop
					if sprite:IsEventTriggered("BlowStop") then
						sprite:SetFrame(8)
					end
				end


			-- Stop blowing
			elseif entity.ProjectileCooldown == 2 then
				entity.Velocity = mod:StopLerp(entity.Velocity, 0.1)

				if sprite:IsFinished() then
					entity.ProjectileCooldown = 0
					entity.State = NpcState.STATE_MOVE
				end
			end
		end



		-- Replace projectiles on death
		if entity:IsDead() then
			if entity.I2 > 1 then
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_TEAR

				-- X shots
				local shootType = 7
				-- 6 shots
				if entity.I2 == 3 then
					shootType = 9
					params.CircleAngle = 0
				-- 8 shots
				elseif entity.I2 == 4 then
					shootType = 8
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_SPLASH, 0, entity.Position, Vector.Zero, entity)
				end

				entity:FireProjectiles(entity.Position, Vector(8, 6), shootType, params)
			end

			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.DrownedChargerUpdate, EntityType.ENTITY_CHARGER)

function mod:DrownedChargerCollision(entity, target, bool)
	if target.Type == EntityType.ENTITY_HIVE then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.DrownedChargerCollision, EntityType.ENTITY_CHARGER)