local mod = BetterMonsters

local Settings = {
	NewHealth = 700,

	Gravity = 1,
	LandHeight = 8,
	MaxTrites = 3,

	FootOffset = Vector(0, -16),
	HeadOffset = Vector(0, -36),
	LegPointyness = -110,
	WalkJumpStrength = 8,
}



--[[ Head and feet ]]--
function mod:triachnidInit(entity)
	if entity.Variant == 1 then
		entity.MaxHitPoints = Settings.NewHealth
		entity.HitPoints = entity.MaxHitPoints

		entity.PositionOffset = Vector(0, -20)
		entity.DepthOffset = 110
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		entity:SetSize(30, Vector(entity.Scale, entity.Scale), 12)

		local data = entity:GetData()
		data.legs = {}
		data.counter = 0

		-- Create the legs
		for i = 1, 3 do
			-- Foot
			local foot = Isaac.Spawn(entity.Type, 10, entity.SubType, entity.Position + Vector.FromAngle(-90 + i * 120):Resized(20), Vector.Zero, entity):ToNPC()
			foot:GetData().index = i
			foot.Parent = entity
			foot:SetSize(20, Vector(entity.Scale, entity.Scale), 12)
			foot:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_NO_REWARD)
			foot:GetSprite():Load(entity:GetSprite():GetFilename(), true)
			foot:GetSprite():Play("FootIdle", true)


			-- Joint
			local joint = Isaac.Spawn(EntityType.ENTITY_EFFECT, IRFentities.TriachnidLeg, IRFentities.TriachnidJoint, entity.Position, Vector.Zero, entity):ToEffect()
			joint:GetData().index = i
			joint.Parent = entity
			joint.DepthOffset = 200


			-- Leg segments
			local upperLeg = Isaac.Spawn(EntityType.ENTITY_EFFECT, IRFentities.TriachnidLeg, IRFentities.TriachnidUpperLeg, entity.Position, Vector.Zero, entity):ToEffect()
			local lowerLeg = Isaac.Spawn(EntityType.ENTITY_EFFECT, IRFentities.TriachnidLeg, IRFentities.TriachnidLowerLeg, entity.Position, Vector.Zero, entity):ToEffect()

			upperLeg:GetData().index = i
			upperLeg.Parent = entity
			upperLeg.Child = lowerLeg
			upperLeg.DepthOffset = 100

			lowerLeg:GetData().index = i
			lowerLeg.Parent = upperLeg
			lowerLeg.Child = foot
			lowerLeg.DepthOffset = 50


			-- Flip the left leg
			if i == 2 then
				foot:GetSprite().FlipX = true
				joint:GetSprite().FlipX = true
				upperLeg:GetSprite().FlipX = true
				lowerLeg:GetSprite().FlipX = true
			end

			foot:Update()
			joint:Update()
			upperLeg:Update()
			lowerLeg:Update()


			-- Store all segments
			data.legs[i] = {
				foot = foot,
				joint = joint,
				upperLeg = upperLeg,
				lowerLeg = lowerLeg,
			}
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.triachnidInit, EntityType.ENTITY_DADDYLONGLEGS)

function mod:triachnidUpdate(entity)
	if entity.Variant == 1 or entity.Variant == 10 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()
		local room = Game():GetRoom()


		local function startLegMove(leg, pos)
			leg.State = NpcState.STATE_MOVE
			leg:GetSprite():Play("FootStepStart")
			leg.V2 = Vector(0, Settings.WalkJumpStrength)
			leg.TargetPosition = room:FindFreeTilePosition(pos, 10)
			leg.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		end


		--[[ Head ]]--
		if entity.Variant == 1 then
			entity.Velocity = Vector.Zero


			if entity.State == 2 then
				entity.Velocity = Vector.Zero
				

				if not data.init then
					
					data.init = true
					sprite:Play("HeadLiftStart", true)
				end
				--if sprite:IsFinished("HeadLiftStart") then
				if sprite:IsPlaying("HeadLiftStart") and sprite:GetFrame() == 8 then
					for i, leg in pairs(data.legs) do
						local pos = entity.Position + Vector.FromAngle(-90 + i * 120):Resized(80)
						startLegMove(leg.foot, pos)
					end
					sprite:Play("HeadLiftLoop", true)
				end

				if data.legs[1].foot.State == 3 and sprite:IsPlaying("HeadLiftLoop") then
					if entity.ProjectileCooldown <= 0 then
						entity.PositionOffset = mod:Lerp(entity.PositionOffset, Vector(0, -80), 0.1)
					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end
				end

				if entity.PositionOffset.Y <= -70 then
					entity.PositionOffset = Vector(0, -70)
					entity.State = 3
					entity.ProjectileCooldown = 30
					sprite:Play("HeadLiftStop", true)
					data.counter = 1
				end

			-- Idle
			elseif entity.State == NpcState.STATE_IDLE then
				if not data.init then
					entity.State = 2
					entity.ProjectileCooldown = 3
				end
				if not sprite:IsPlaying("HeadLiftStop") then
					mod:LoopingAnim(sprite, "HeadIdle")
				end

				if entity.ProjectileCooldown <= 0 then
					data.counter = data.counter + 1

					if data.counter >= 3 then
						-- Reset variables
						entity.ProjectileCooldown = Settings.Cooldown or 10
						entity.I1 = 0
						entity.I2 = 0
						entity.StateFrame = 0
						entity.ProjectileDelay = 0
						data.counter = 0

						-- Choose an attack
						local attackCount = 4
						-- Only have up to 3 Trites
						if Isaac.CountEntities(nil, EntityType.ENTITY_HOPPER, 1, -1) >= Settings.MaxTrites then
							attackCount = 3
						end
						local attack = mod:Random(1, attackCount)
						--attack = 2

						-- Vomit attack
						if attack == 1 then
							entity.State = NpcState.STATE_ATTACK
							sprite:Play("HeadVomitStart", true)
							entity.V1 = Vector(mod:Random(359), 0)
							mod:PlaySound(entity, SoundEffect.SOUND_FAT_WIGGLE)

						-- Stomp attack
						elseif attack == 2 then
							entity.State = NpcState.STATE_ATTACK2
							sprite:Play("HeadLiftStart", true)
							mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_1)

						-- Head slam attack
						elseif attack == 3 then
							entity.State = NpcState.STATE_ATTACK2
							sprite:Play("HeadLiftStart", true)
							mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_1)
							--entity.State = NpcState.STATE_ATTACK3
							--entity.TargetPosition = entity.Position + (target.Position - entity.Position):Resized(200)
							--entity.TargetPosition = Game():GetRoom():GetClampedPosition(entity.TargetPosition, 40)

						-- Spit out an egg sack
						elseif attack == 4 then
							entity.State = NpcState.STATE_SUMMON
							sprite:Play("HeadSpit", true)
						end

					else
						entity.State = NpcState.STATE_MOVE

						if data.init then
							entity.TargetPosition = entity.Position + (target.Position - entity.Position):Resized(120)
							entity.TargetPosition = room:GetClampedPosition(entity.TargetPosition, 40)
						else
							entity.TargetPosition = entity.Position
							data.init = true
						end
					end

					data.sortedLegs = {
						data.legs[1].foot,
						data.legs[2].foot,
						data.legs[3].foot,
					}
					table.sort(data.sortedLegs, function (k1, k2) return k1.Position:Distance(target.Position) < k2.Position:Distance(target.Position) end )

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end


			-- Moving
			elseif entity.State == NpcState.STATE_MOVE then
				-- Stay at the centroid of the feet
				local centroidX = 0
				local centroidY = 0
				for i, leg in pairs(data.legs) do
					centroidX = centroidX + leg.foot.Position.X
					centroidY = centroidY + leg.foot.Position.Y
				end

				entity.Position = Vector(centroidX, centroidY) / 3


				--entity.I2 = 100
				if entity.I2 <= 0 then
					-- Move the first leg on the list
					if data.sortedLegs[1] then
						local pos = entity.TargetPosition + Vector.FromAngle(-90 + data.sortedLegs[1]:GetData().index * 120):Resized(80)
						startLegMove(data.sortedLegs[1], pos)
						table.remove(data.sortedLegs, 1)
						entity.I2 = 25

					-- Get new direction
					else
						entity.State = NpcState.STATE_IDLE
					end

				else
					entity.I2 = entity.I2 - 1
				end


			-- Vomit attack
			elseif entity.State == NpcState.STATE_ATTACK then
				-- Start
				if entity.StateFrame == 0 then
					if sprite:IsFinished() then
						entity.StateFrame = 1
						--mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR)
						mod:PlaySound(nil, SoundEffect.SOUND_PESTILENCE_NECK_PUKE, 1.1)
					end

				-- Loop
				elseif entity.StateFrame == 1 then
					mod:LoopingAnim(sprite, "HeadVomitLoop")

					if entity.ProjectileDelay <= 0 then
						-- Projectiles
						local params = ProjectileParams()
						params.Scale = 1 + mod:Random(10, 80) / 100
						params.Color = IRFcolors.WhiteShot

						local angle = entity.V1.X + entity.I2 * 666 -- This is dumb
						entity:FireProjectiles(entity.Position, Vector.FromAngle(angle):Resized(mod:Random(6, 12)), 0, params)
						entity:FireProjectiles(entity.Position, Vector.FromAngle(angle + 69):Resized(mod:Random(5, 10)), 0, params)

						-- Creep
						if entity.I2 % 2 == 0 then
							mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position + mod:RandomVector(mod:Random(50)), 2 + mod:Random(50) / 100)
							mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 0.75)
						end

						entity.I2 = entity.I2 + 1
						entity.ProjectileDelay = 2

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I2 >= 20 then
						entity.StateFrame = 2
						sprite:Play("HeadVomitStop", true)
					end

				-- Stop
				elseif entity.StateFrame == 2 then
					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end
				end


			-- Stomp attack
			elseif entity.State == NpcState.STATE_ATTACK2 then
				-- Start
				if entity.StateFrame == 0 then
					if sprite:IsFinished() then
						entity.StateFrame = 1
					end

				-- Loop
				elseif entity.StateFrame == 1 then
					mod:LoopingAnim(sprite, "HeadLiftLoop")

				-- Stop
				elseif entity.StateFrame == 2 then
					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end
				end
				if entity.StateFrame ~= 2 and data.sortedLegs[1].State ~= NpcState.STATE_ATTACK then
					data.sortedLegs[1].State = NpcState.STATE_ATTACK
					data.sortedLegs[1].GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					data.sortedLegs[1].EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					data.sortedLegs[1]:GetSprite():Play("FootStepStart", true)
					data.sortedLegs[1].I1 = 30
				end


			-- Head slam attack
			elseif entity.State == NpcState.STATE_ATTACK3 then
				entity.PositionOffset = mod:Lerp(entity.PositionOffset, Vector(entity.PositionOffset.X, -200), 0.15)
				--


			-- Spit out an egg sack
			elseif entity.State == NpcState.STATE_SUMMON then
				if sprite:IsEventTriggered("Vomit") then
					--Isaac.Spawn(EntityType.ENTITY_SINGE, 1, 0, entity.Position, (target.Position - entity.Position):Resized(6), entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					local trite = Isaac.Spawn(EntityType.ENTITY_BLISTER, 0, 0, entity.Position, Vector.Zero, entity):ToNPC()
					local triteSprite = trite:GetSprite()

					trite.State = NpcState.STATE_JUMP
					triteSprite:Play("Hop", true)
					triteSprite:SetFrame(3)

					--local pos = entity.Position + (target.Position - entity.Position):Resized(240)
					--trite.TargetPosition = room:GetClampedPosition(pos, 10)

					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF, 0.8)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end



		--[[ Feet ]]--
		elseif entity.Variant == 10 then
			-- Remove if it doesn't have a parent
			if not entity.Parent then
				entity:Remove()

			-- On parent death
			elseif entity.Parent:IsDead() then
				entity.State = NpcState.STATE_IDLE
				entity.Velocity = Vector.Zero
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

				-- Put them down on the ground
				if entity.PositionOffset.Y < 0 then
					entity.PositionOffset = Vector.Zero
					sprite:Play("FootStomp", true)
				else
					sprite:Play("FootIdle", true)
				end


			else
				entity.MaxHitPoints = entity.Parent.MaxHitPoints
				entity.HitPoints = entity.Parent.HitPoints

				-- Idle
				if entity.State == NpcState.STATE_IDLE then
					entity.Velocity = Vector.Zero
					if not sprite:IsPlaying("FootStomp") then
						mod:LoopingAnim(sprite, "FootIdle")
					end


				-- Moving
				elseif entity.State == NpcState.STATE_MOVE then
					if not sprite:IsPlaying("FootStepStart") then
						mod:LoopingAnim(sprite, "FootAir")
					end
					mod:FlipTowardsMovement(entity, sprite)

					-- Update height
					entity.V2 = Vector(0, entity.V2.Y - Settings.Gravity)
					entity.PositionOffset = Vector(0, math.min(Settings.LandHeight, entity.PositionOffset.Y - entity.V2.Y))

					-- Land
					if entity.Position:Distance(entity.TargetPosition) < 20 then
						entity.Velocity = mod:StopLerp(entity.Velocity)

						if entity.PositionOffset.Y >= Settings.LandHeight then
							entity.State = NpcState.STATE_IDLE
							sprite:Play("FootStomp")
							entity.PositionOffset = Vector.Zero
							entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
							mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.4)
						end

					-- Move to position
					else
						entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(entity.TargetPosition:Distance(entity.Position) / 8), 0.25)
					end


				-- Stomp
				elseif entity.State == NpcState.STATE_ATTACK then
					-- Go above the target
					if entity.StateFrame == 0 then
						if not sprite:IsPlaying("FootStepStart") then
							mod:LoopingAnim(sprite, "FootAir")
						end
						mod:FlipTowardsMovement(entity, sprite)

						-- Update height
						entity.PositionOffset = mod:Lerp(entity.PositionOffset, Vector(entity.PositionOffset.X, -120), 0.15)

						-- Get the position to move to
						local length = math.min(320, (target.Position):Distance(entity.Parent.Position))
						entity.TargetPosition = entity.Parent.Position + (target.Position - entity.Parent.Position):Resized(length)

						-- Stomp delay
						if entity.I1 > 0 then
							entity.I1 = entity.I1 - 1
						end

						-- Land
						if entity.Position:Distance(entity.TargetPosition) < 20 then
							entity.Velocity = mod:StopLerp(entity.Velocity)

							if entity.I1 <= 0 then
								entity.StateFrame = 1
								mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8)
							end

						-- Move to position
						else
							entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(10 + entity.TargetPosition:Distance(entity.Position) / 25), 0.25)
						end


					-- Come down
					elseif entity.StateFrame == 1 then
						entity.Velocity = Vector.Zero
						mod:LoopingAnim(sprite, "FootAir")

						-- Land
						if entity.PositionOffset.Y >= Settings.LandHeight then
							entity.StateFrame = 2
							sprite:Play("FootStomp")
							entity.PositionOffset = Vector.Zero
							entity.I1 = 20

							entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
							entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

							-- Projectiles + creep
							local params = ProjectileParams()
							params.Color = IRFcolors.WhiteShot
							entity:FireProjectiles(entity.Position, Vector(10, 8), 8, params)
							mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position, 2)

							-- Effects
							local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity)
							effect.DepthOffset = entity.DepthOffset + 10
							effect:GetSprite().Color = IRFcolors.WhiteShot

							mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.9)
							mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 0.9)
							Game():ShakeScreen(9)

							-- Destroy rocks he slams
							room:DestroyGrid(room:GetGridIndex(entity.Position), true)

						-- Going down
						else
							entity.I1 = entity.I1 + 2 -- Increase the speed
							entity.PositionOffset = Vector(entity.PositionOffset.X, entity.PositionOffset.Y + (20 + entity.I1))
						end


					-- Landed
					elseif entity.StateFrame == 2 then
						entity.Velocity = Vector.Zero
						if not sprite:IsPlaying("FootStomp") then
							mod:LoopingAnim(sprite, "FootIdle")
						end

						-- Go back to the head
						if entity.I1 <= 0 then
							local pos = entity.Parent.Position + Vector.FromAngle(-90 + data.index * 120):Resized(80)
							startLegMove(entity, pos)
							entity.StateFrame = 0

							-- Set the head back to the idle state
							--entity.Parent:ToNPC().State = NpcState.STATE_MOVE
							entity.Parent:ToNPC().StateFrame = 2
							entity.Parent:GetSprite():Play("HeadLiftStop", true)
							entity.Parent:ToNPC().ProjectileCooldown = 60

						else
							entity.I1 = entity.I1 - 1
						end
					end
				end
			end
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.triachnidUpdate, EntityType.ENTITY_DADDYLONGLEGS)

function mod:triachnidDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 10 and target.Parent then
		target.Parent:TakeDamage(damageAmount, damageFlags + DamageFlag.DAMAGE_COUNTDOWN, damageSource, 1)
		target:SetColor(IRFcolors.DamageFlash, 2, 0, false, true)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.triachnidDMG, EntityType.ENTITY_DADDYLONGLEGS)



--[[ Legs ]]--			Heavily based off of Dusk's elbow code from Fiend Folio (thanks Erfly!)
function mod:triachnidRender(entity, offset)
	if not Game():IsPaused() and entity.Variant == 1 and entity:GetData().legs then
		local data = entity:GetData()
		local sprite = entity:GetSprite()


		-- Update join positions
		for i, leg in pairs(data.legs) do
			if leg.upperLeg and leg.foot then
				-- Get positions
				local startpos = entity.Position + entity.PositionOffset + Settings.HeadOffset
				local endpos = leg.foot.Position + leg.foot.PositionOffset + Settings.FootOffset
				local halfway = (endpos - startpos) / 2

				-- Top leg is handled differently
				if i == 3 then
					leg.joint.Position = startpos + halfway + Vector(0, Settings.LegPointyness + 10)

				else
					-- Get direction
					local flippedness = leg.upperLeg:GetSprite().FlipX == true and -1 or 1

					local multi = 1
					if leg.foot.State == NpcState.STATE_ATTACK then
						multi = -mod:GetSign(leg.foot.Position.Y < entity.Position.Y)
					end

					leg.joint.Position = startpos + halfway + halfway:Rotated(90 * flippedness):Resized(Settings.LegPointyness)
				end
			end
		end


		-- Death stuff
		if sprite:IsPlaying("Death") then
			-- Fall down to the ground
			if sprite:GetFrame() >= 11 then
				if entity.PositionOffset.Y < -10 then
					-- Get falling speed
					if not data.deathFallSpeed then
						data.deathFallSpeed = 0
					else
						data.deathFallSpeed = data.deathFallSpeed + 1
					end

					entity.PositionOffset = Vector(entity.PositionOffset.X, entity.PositionOffset.Y + data.deathFallSpeed)

					if sprite:GetFrame() >= 12 then
						sprite:SetFrame(11)
					end

				-- Landed
				elseif data.deathFallSpeed then
					data.deathFallSpeed = nil
					entity.PositionOffset = Vector(entity.PositionOffset.X, -10)
					sprite.Offset = Vector(0, -10)
					sprite:SetFrame(12)

					-- Effects
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity).DepthOffset = entity.DepthOffset + 10
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS)
					mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND)
					Game():ShakeScreen(10)
				end
			end

			-- Remove the legs
			if sprite:GetFrame() == 22 then
				for i, leg in pairs(data.legs) do
					for j, segment in pairs(leg) do
						segment:Remove()

						-- Bone gibs
						if segment.Type == EntityType.ENTITY_EFFECT and segment.SubType == 2 then
							local boneEffect = Isaac.Spawn(EntityType.ENTITY_BONY, 0, 0, segment.Position, Vector.Zero, entity)
							boneEffect.Visible = false
							boneEffect:Kill()
						end
					end
				end

				data.legs = nil
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.triachnidRender, EntityType.ENTITY_DADDYLONGLEGS)

-- Update leg segments
function mod:triachnidLegSegmentUpdate(entity)
	if entity.SpawnerEntity then
		local sprite = entity:GetSprite()
		local data = entity:GetData()

		-- Joint
		if entity.SubType == IRFentities.TriachnidJoint then
			mod:LoopingAnim(sprite, "Joint")


		-- Leg segments
		else
			mod:LoopingAnim(sprite, "Leg")

			local joint
			if entity.SpawnerEntity:GetData().legs[data.index] then
				joint = entity.SpawnerEntity:GetData().legs[data.index].joint.Position
			end

			if joint and ((entity.SubType == IRFentities.TriachnidUpperLeg and entity.Parent) or (entity.SubType == IRFentities.TriachnidLowerLeg and entity.Child)) then
				-- Get direction
				local flippedness = sprite.FlipX == true and -1 or 1

				-- Get where to point towards
				local endpos = entity.Parent.Position + entity.Parent.PositionOffset + Settings.HeadOffset
				if entity.SubType == IRFentities.TriachnidLowerLeg then
					endpos = entity.Child.Position + entity.Child.PositionOffset + Settings.FootOffset
				end

				entity.Position = (joint + endpos) / 2
				sprite.Rotation = (endpos - joint):GetAngleDegrees() * flippedness
				sprite.Scale = Vector(1, joint:Distance(endpos) / 200)
			end
		end


	else
		entity:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.triachnidLegSegmentUpdate, IRFentities.TriachnidLeg)