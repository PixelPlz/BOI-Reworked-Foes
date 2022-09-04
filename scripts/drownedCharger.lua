local mod = BetterMonsters
local game = Game()



function mod:drownedChargerUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()

		-- Check if it was charging
		if entity.State == NpcState.STATE_ATTACK then
			data.wasCharging = true

		else
			if data.wasCharging == true then
				entity.State = NpcState.STATE_JUMP
				data.wasCharging = false
				data.wasFlipped = sprite.FlipX

				local dir = "Hori"
				if entity.V1.Y < 0 then
					dir = "Up"
				elseif entity.V1.Y > 0 then
					dir = "Down"
				end
				sprite:Play("Blow " .. dir, true)
			end
			
			if entity.State == NpcState.STATE_JUMP then
				-- Make sure it faces the right direction
				if data.wasFlipped == true then
					sprite.FlipX = true
				else
					sprite.FlipX = false
				end

				if sprite:IsEventTriggered("BlowStart") then
					data.attacking = true
				elseif sprite:IsEventTriggered("BlowStop") then
					data.attacking = false
				end
				if sprite:GetFrame() == 33 then
					entity.State = NpcState.STATE_MOVE
				end
				
				-- Shoot + push back
				if data.attacking == true then
					entity.Velocity = -entity.V1:Normalized() * 4

					if entity:IsFrame(4, 0) then
						local params = ProjectileParams()
						params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
						params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
						params.ChangeTimeout = 75

						params.Acceleration = 1.1
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.2
						params.Scale = 1 + (math.random(25, 40) * 0.01)
						params.HeightModifier = 19
						params.Variant = ProjectileVariant.PROJECTILE_TEAR

						entity:FireProjectiles(entity.Position + entity.V1:Normalized() * 7, Vector.FromAngle(entity.V1:GetAngleDegrees() + math.random(-30, 30)) * math.random(4, 8), 0, params)
						entity:PlaySound(SoundEffect.SOUND_BOSS2_BUBBLES, 0.75, 0, false, 1)
					end

				else
					entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.drownedChargerUpdate, EntityType.ENTITY_CHARGER)

function mod:drownedChargerPreUpdate(entity)
	if entity.Variant == 1 and entity:IsDead() then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.drownedChargerPreUpdate, EntityType.ENTITY_CHARGER)