local mod = BetterMonsters

local Settings = {
	SideRange = 25,
	FrontRange = 100,
	Cooldown = 5,
	WhipStrength = 5
}



function mod:nerveEnding2Init(entity)
	if entity.Variant == 1 then
		entity.ProjectileCooldown = 20
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.nerveEnding2Init, EntityType.ENTITY_NERVE_ENDING)

function mod:nerveEnding2Update(entity)
	if entity.Variant == 1 then
		local data = entity:GetData()
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		
		
		entity.Velocity = Vector.Zero
		
		-- Idle
		if entity.State == 3 then
			mod:LoopingAnim(sprite, "Idle")
			
			if entity.ProjectileCooldown <= 0 then
				-- Attack if in range
				if Game():GetRoom():CheckLine(entity.Position, target.Position, 3, 0, false, false) then
					-- Horizontal
					if entity.Position.Y <= target.Position.Y + Settings.SideRange and entity.Position.Y >= target.Position.Y - Settings.SideRange then
						if target.Position.X > (entity.Position.X - Settings.FrontRange) and target.Position.X < entity.Position.X then
							data.swingDir = "Left"
							entity.State = 8
							sprite:Play("Swing" .. data.swingDir, true)

						elseif target.Position.X < (entity.Position.X + Settings.FrontRange) and target.Position.X > entity.Position.X then
							data.swingDir = "Right"
							entity.State = 8
							sprite:Play("Swing" .. data.swingDir, true)
						end

					-- Vertical
					elseif entity.Position.X <= target.Position.X + Settings.SideRange and entity.Position.X >= target.Position.X - Settings.SideRange then
						if target.Position.Y > (entity.Position.Y - Settings.FrontRange) and target.Position.Y < entity.Position.Y then
							data.swingDir = "Up"
							entity.State = 8
							sprite:Play("Swing" .. data.swingDir, true)

						elseif target.Position.Y < (entity.Position.Y + Settings.FrontRange) and target.Position.Y > entity.Position.Y then
							data.swingDir = "Down"
							entity.State = 8
							sprite:Play("Swing" .. data.swingDir, true)
						end
					end
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Attack
		elseif entity.State == 8 then
			if sprite:IsEventTriggered("Sound") then
				SFXManager():Play(SoundEffect.SOUND_WHIP)

			elseif sprite:IsEventTriggered("Hit") then				
				local hurt = false

				-- Check if it hit the target
				if Game():GetRoom():CheckLine(entity.Position, target.Position, 3 - entity.Variant, 0, false, false) then
					if data.swingDir == "Left" or data.swingDir == "Right" then
						if entity.Position.Y <= target.Position.Y + Settings.SideRange and entity.Position.Y >= target.Position.Y - Settings.SideRange then
							if data.swingDir == "Left" and target.Position.X > (entity.Position.X - Settings.FrontRange) and target.Position.X < entity.Position.X
							or data.swingDir == "Right" and target.Position.X < (entity.Position.X + Settings.FrontRange) and target.Position.X > entity.Position.X then
								hurt = true
							end
						end

					elseif data.swingDir == "Up" or data.swingDir == "Down" then
						if entity.Position.X <= target.Position.X + Settings.SideRange and entity.Position.X >= target.Position.X - Settings.SideRange then
							if data.swingDir == "Up" and target.Position.Y > (entity.Position.Y - Settings.FrontRange) and target.Position.Y < entity.Position.Y
							or data.swingDir == "Down" and target.Position.Y < (entity.Position.Y + Settings.FrontRange) and target.Position.Y > entity.Position.Y then
								hurt = true
							end
						end
					end
				end
				
				-- On succesful hit
				if hurt == true then
					target:TakeDamage(2, 0, EntityRef(entity), 0)
					target.Velocity = target.Velocity + (Vector.FromAngle((target.Position - entity.Position):GetAngleDegrees()) * Settings.WhipStrength)
					SFXManager():Play(SoundEffect.SOUND_WHIP_HIT)
				end
			end

			if sprite:IsFinished(sprite:GetAnimation()) then
				entity.State = 3
				entity.ProjectileCooldown = Settings.Cooldown
			end
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.nerveEnding2Update, EntityType.ENTITY_NERVE_ENDING)