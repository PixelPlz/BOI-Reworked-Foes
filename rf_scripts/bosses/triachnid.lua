local mod = BetterMonsters

local Settings = {
	NewHealth = 700,
	LegDamageReduction = 20,
	Cooldown = 30,
	MaxSpawns = 3,

	-- Head
	HeadHeight = -70,
	RaisedHeadHeight = -140,
	HeadOffset = Vector(0, -36),

	-- Feet
	FootOffset = Vector(0, -16),
	LegPointyness = 110,

	WalkJumpStrength = 11,
	Gravity = 1.2,
	LandHeight = 0,
	StompDamage = 40, -- Just enough to kill a half health Blister in the Void (why do they have so much stage HP...)
}



--[[ Head and feet ]]--
function mod:triachnidInit(entity)
	if entity.Variant == 1 then
		entity.MaxHitPoints = Settings.NewHealth
		entity.HitPoints = entity.MaxHitPoints

		entity.PositionOffset = Vector(0, -20)
		entity:SetSize(30, Vector(entity.Scale, entity.Scale), 12)
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		entity.DepthOffset = 110

		local data = entity:GetData()
		data.moveCounter = 1
		data.stompDelay = 0


		-- Create the legs
		data.legs = {}

		for i = 1, 3 do
			-- Foot
			local foot = Isaac.Spawn(entity.Type, 10, entity.SubType, entity.Position + Vector.FromAngle(-90 + i * 120):Resized(20), Vector.Zero, entity):ToNPC()
			foot:GetData().index = i
			foot.Parent = entity
			foot:SetSize(20, Vector(entity.Scale, entity.Scale), 12)
			foot:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_NO_REWARD)

			local footSprite = foot:GetSprite()
			footSprite:Load(entity:GetSprite():GetFilename(), true)
			footSprite:Play("FootIdle", true)


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


		-- Make a leg move to the specified spot
		local function startLegMove(leg, pos)
			leg.State = NpcState.STATE_MOVE
			leg:GetSprite():Play("FootStepStart")
			leg.V2 = Vector(0, Settings.WalkJumpStrength)
			leg.TargetPosition = room:FindFreeTilePosition(pos, 20)
			leg.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		end


		--[[ Head ]]--
		if entity.Variant == 1 then
			entity.Velocity = Vector.Zero

			-- Uncurl
			if entity.State == NpcState.STATE_APPEAR_CUSTOM then
				-- Start
				if entity.StateFrame == 0 then
					if sprite:IsFinished() then
						entity.StateFrame = 1

						for i, leg in pairs(data.legs) do
							local pos = entity.Position + Vector.FromAngle(-90 + i * 120):Resized(80)
							startLegMove(leg.foot, pos)
						end
					end

				-- Wait for the feet to land
				elseif entity.StateFrame == 1 then
					mod:LoopingAnim(sprite, "HeadLiftLoop")

				-- Get up
				elseif entity.StateFrame == 2 then
					mod:LoopingAnim(sprite, "HeadLiftLoop")

					-- Delay
					if entity.I2 <= 0 then
						-- Up and ready
						if entity.PositionOffset.Y <= Settings.HeadHeight then
							sprite:Play("HeadLiftStop", true)
							entity.State = NpcState.STATE_IDLE
							entity.PositionOffset = Vector(0, Settings.HeadHeight)

							entity.StateFrame = 0
							entity.ProjectileCooldown = Settings.Cooldown / 2
							data.init = true

						else
							entity.PositionOffset = mod:Lerp(entity.PositionOffset, Vector(0, Settings.HeadHeight - 10), 0.1)
						end

					else
						entity.I2 = entity.I2 - 1
					end
				end


			-- Idle
			elseif entity.State == NpcState.STATE_IDLE then
				-- Do the appear animation first
				if not data.init then
					entity.State = NpcState.STATE_APPEAR_CUSTOM
					sprite:Play("HeadLiftStart", true)
					entity.StateFrame = 0
					entity.I2 = 3
					mod:PlaySound(entity, IRFsounds.TriachnidHappy, 1.2)


				else
					if not sprite:IsPlaying("HeadLiftStop") then
						mod:LoopingAnim(sprite, "HeadIdle")
					end

					-- Move / attack cooldown
					if entity.ProjectileCooldown <= 0 then
						data.moveCounter = data.moveCounter + 1

						-- Attack after every 2 moves
						if data.moveCounter >= 3 then
							-- Reset variables
							entity.ProjectileCooldown = Settings.Cooldown
							--entity.I1 = 0
							entity.I2 = 0
							entity.StateFrame = 0
							entity.ProjectileDelay = 0
							data.moveCounter = 0

							-- Choose an attack
							local attackCount = 4
							-- Only have up to 3 Trites / Sacks
							if Isaac.CountEntities(nil, EntityType.ENTITY_BLISTER, -1, -1) + Isaac.CountEntities(nil, EntityType.ENTITY_BOIL, 2, -1) >= Settings.MaxSpawns then
								attackCount = 3
							end
							local attack = mod:Random(1, attackCount)
							if attack == 3 then attack = 2 end

							--attack = 4

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
								entity.State = NpcState.STATE_ATTACK3
								sprite:Play("HeadLiftStart", true)
								entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

							-- Spit out an egg sack
							elseif attack == 4 then
								entity.State = NpcState.STATE_SUMMON
								sprite:Play("HeadSpit", true)
							end


						-- Move
						else
							entity.State = NpcState.STATE_MOVE
							entity.TargetPosition = entity.Position + (target.Position - entity.Position):Resized(120)
							entity.TargetPosition = room:GetClampedPosition(entity.TargetPosition, 40)
						end


						-- Sort the legs by distance from the target
						data.sortedLegs = {
							data.legs[1].foot,
							data.legs[2].foot,
							data.legs[3].foot,
						}
						table.sort(data.sortedLegs, function (k1, k2) return k1.Position:Distance(target.Position) < k2.Position:Distance(target.Position) end )

					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end
				end


			-- Moving
			elseif entity.State == NpcState.STATE_MOVE then
				-- Stay at the centroid of the feet
				local centroidX = 0
				local centroidY = 0
				local combinedHeight = 0

				for i, leg in pairs(data.legs) do
					centroidX = centroidX + leg.foot.Position.X
					centroidY = centroidY + leg.foot.Position.Y
					combinedHeight = combinedHeight + leg.foot.PositionOffset.Y
				end

				entity.Position = Vector(centroidX, centroidY) / 3
				entity.PositionOffset = Vector(0, Settings.HeadHeight + combinedHeight * 0.18)


				if data.stompDelay <= 0 then
					-- Move the first leg on the list
					if data.sortedLegs[1] then
						local pos = entity.TargetPosition + Vector.FromAngle(-90 + data.sortedLegs[1]:GetData().index * 120):Resized(80)
						startLegMove(data.sortedLegs[1], pos)
						table.remove(data.sortedLegs, 1)

						-- Stomp faster the lower his health is
						local onePercent = entity.MaxHitPoints / 100
						local currentPercent = entity.HitPoints / onePercent
						local difference = 100 - currentPercent

						data.stompDelay = 30 - math.ceil(difference / 10)

					-- All legs have moved
					else
						entity.State = NpcState.STATE_IDLE
					end

				else
					data.stompDelay = data.stompDelay - 1
				end


			-- Vomit attack
			elseif entity.State == NpcState.STATE_ATTACK then
				-- Start
				if entity.StateFrame == 0 then
					if sprite:IsFinished() then
						entity.StateFrame = 1
						if not data.wasDelirium then -- I hate this game
							mod:PlaySound(nil, SoundEffect.SOUND_PESTILENCE_NECK_PUKE, 1.1)
						end
					end

				-- Loop
				elseif entity.StateFrame == 1 then
					mod:LoopingAnim(sprite, "HeadVomitLoop")

					if entity.ProjectileDelay <= 0 and not data.wasDelirium then
						-- Projectiles
						local params = ProjectileParams()
						params.Scale = 1 + mod:Random(10, 80) / 100
						params.Color = IRFcolors.WhiteShot

						local angle = entity.V1.X + entity.I2 * 666
						entity:FireProjectiles(entity.Position, Vector.FromAngle(angle):Resized(mod:Random(6, 12)), 0, params)
						entity:FireProjectiles(entity.Position, Vector.FromAngle(angle + 69):Resized(mod:Random(5, 10)), 0, params)

						-- Creep
						if entity.I2 % 2 == 0 then
							mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position + mod:RandomVector(mod:Random(50)), 2 + mod:Random(50) / 100, 240)
							mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 0.75)
						end
						if entity.I2 % 5 == 0 then
							Isaac.GridSpawn(GridEntityType.GRID_SPIDERWEB, 0, entity.Position + mod:RandomVector(10 + entity.I2 * 3), false)
						end

						entity.I2 = entity.I2 + 1
						entity.ProjectileDelay = 2

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I2 >= 25 then
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
				-- Set the foot's state
				if entity.StateFrame < 2 and data.sortedLegs[1].State ~= NpcState.STATE_ATTACK then
					data.sortedLegs[1].State = NpcState.STATE_ATTACK
					data.sortedLegs[1]:GetSprite():Play("FootStepStart", true)
					data.sortedLegs[1].I1 = 30

					data.sortedLegs[1].EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					data.sortedLegs[1].GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				end

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


			-- Head slam attack
			elseif entity.State == NpcState.STATE_ATTACK3 then
				-- Stay at the centroid of the feet
				local centroidX = 0
				local centroidY = 0
				local combinedHeight = 0

				for i, leg in pairs(data.legs) do
					centroidX = centroidX + leg.foot.Position.X
					centroidY = centroidY + leg.foot.Position.Y
					combinedHeight = combinedHeight + leg.foot.PositionOffset.Y
				end

				entity.Position = Vector(centroidX, centroidY) / 3


				-- >:(
				if entity.StateFrame == 1 then
					if sprite:IsFinished() then
						entity.StateFrame = 1
						
					end

				-- Lift head
				elseif entity.StateFrame == 0 then
					if not sprite:IsPlaying("HeadLiftStart") then
						mod:LoopingAnim(sprite, "HeadLiftLoop")
					end

					if entity.PositionOffset.Y <= Settings.RaisedHeadHeight then
						entity.StateFrame = 2
						entity.PositionOffset = Vector(0, Settings.RaisedHeadHeight)
						sprite.Offset = Vector(0, -15)

						entity.TargetPosition = entity.Position + (target.Position - entity.Position):Resized(200)
						entity.TargetPosition = room:GetClampedPosition(entity.TargetPosition, 40)


						-- Sort the legs by distance from the parent
						--[[
						data.sortedLegs = {
							data.legs[1].foot,
							data.legs[2].foot,
							data.legs[3].foot,
						}
						table.sort(data.sortedLegs, function (k1, k2) return k1.Position:Distance(entity.Position) > k2.Position:Distance(entity.Position) end )
						]]--

					else
						entity.PositionOffset = mod:Lerp(entity.PositionOffset, Vector(entity.PositionOffset.X, Settings.RaisedHeadHeight - 10), 0.1)
						sprite.Offset = mod:Lerp(sprite.Offset, Vector(0, -15), 0.1)
					end

				-- Move to position
				elseif entity.StateFrame == 2 then
					mod:LoopingAnim(sprite, "HeadLiftLoop")

					-- Stay at the centroid of the feet
					local centroidX = 0
					local centroidY = 0
					local combinedHeight = 0

					for i, leg in pairs(data.legs) do
						centroidX = centroidX + leg.foot.Position.X
						centroidY = centroidY + leg.foot.Position.Y
						combinedHeight = combinedHeight + leg.foot.PositionOffset.Y
					end

					entity.Position = Vector(centroidX, centroidY) / 3
					entity.PositionOffset = Vector(0, Settings.RaisedHeadHeight + combinedHeight * 0.18)


					if entity.Position:Distance(target.Position) < entity.Size * entity.Scale + 30 then
						entity.StateFrame = 3
						sprite:Play("HeadFallStart", true)
						entity.I2 = 0
					end
					
					if data.stompDelay <= 0 then
						
	
						local neew = entity.Position + (target.Position - entity.Position):Resized(120)
						entity.TargetPosition = mod:Lerp(entity.TargetPosition, neew, 0.5)

						-- Move the first leg on the list
						if data.sortedLegs[1] then
							local pos = entity.TargetPosition + Vector.FromAngle(-90 + data.sortedLegs[1]:GetData().index * 120):Resized(80)
							--local pos = entity.Position + (target.Position - entity.Position):Resized(200) + Vector.FromAngle(-90 + data.sortedLegs[1]:GetData().index * 120):Resized(80)

							startLegMove(data.sortedLegs[1], pos, true)
							data.lastLeg = data.sortedLegs[1]:GetData().index
							table.remove(data.sortedLegs, 1)

							-- Stomp faster the lower his health is
							local onePercent = entity.MaxHitPoints / 100
							local currentPercent = entity.HitPoints / onePercent
							local difference = 100 - currentPercent

							data.stompDelay = 25 - math.ceil(difference / 10)

						-- All legs have moved
						else
							if entity.I2 >= 2 or entity.Position:Distance(target.Position) < entity.Size * entity.Scale + 30 then
								entity.StateFrame = 3
								sprite:Play("HeadFallStart", true)
								entity.I2 = 0

							else
								entity.I2 = entity.I2 + 1
								entity.TargetPosition = entity.Position + (target.Position - entity.Position):Resized(120)
								entity.TargetPosition = room:GetClampedPosition(entity.TargetPosition, 40)

								-- Sort the legs by distance from the target
								data.sortedLegs = {
									data.legs[1].foot,
									data.legs[2].foot,
									data.legs[3].foot,
								}
								table.sort(data.sortedLegs, function (k1, k2) return k1.Position:Distance(target.Position) < k2.Position:Distance(target.Position) end )

								-- Start with the furthest
								if data.sortedLegs[1]:GetData().index == data.lastLeg then
									table.sort(data.sortedLegs, function (k1, k2) return k1.Position:Distance(target.Position) > k2.Position:Distance(target.Position) end )
								end
							end
						end

					else
						data.stompDelay = data.stompDelay - 1
					end

				-- Start going down
				elseif entity.StateFrame == 3 then
					if sprite:IsFinished() then
						entity.StateFrame = 4
					end

				-- Falling
				elseif entity.StateFrame == 4 then
					mod:LoopingAnim(sprite, "HeadFallLoop")

					-- Land
					if entity.PositionOffset.Y >= Settings.LandHeight - 10 then
						entity.StateFrame = 5
						sprite:Play("HeadSlam")
						entity.PositionOffset = Vector.Zero
						entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

						-- Projectiles + creep
						local params = ProjectileParams()
						params.Color = IRFcolors.WhiteShot
						params.CircleAngle = 0
						entity:FireProjectiles(entity.Position, Vector(10, 16), 9, params)

						-- Creep
						local offset = mod:Random(359)
						for i = 0, 3 do
							mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position + Vector.FromAngle(offset + i * 90):Resized(50), 2.5)
						end

						-- Effects
						local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity)
						effect.DepthOffset = entity.DepthOffset + 10
						effect:GetSprite().Color = IRFcolors.WhiteShot

						mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.2)
						mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1.2)
						Game():ShakeScreen(10)

						-- Destroy rocks he slams
						for i = -1, 1 do
							for j = -1, 1 do
								local gridPos = entity.Position + Vector(i * 30, j * 30)
								room:DestroyGrid(room:GetGridIndex(gridPos), true)
							end
						end

						-- Damage enemies he slams
						for i, enemy in pairs(Isaac.FindInRadius(entity.Position, entity.Size * entity.Scale + 15, EntityPartition.ENEMY)) do
							if enemy.Type ~= entity.Type and enemy.EntityCollisionClass >= 3 and enemy.Visible == true and enemy:IsActiveEnemy() == true then
								enemy:TakeDamage(Settings.StompDamage * 2, DamageFlag.DAMAGE_CRUSH, EntityRef(entity.Parent), 0)
							end
						end

					-- Going down
					else
						entity.I2 = entity.I2 + 2 -- Increase the speed
						entity.PositionOffset = Vector(entity.PositionOffset.X, entity.PositionOffset.Y + (20 + entity.I2))
					end

				-- Landed
				elseif entity.StateFrame == 5 then
					if sprite:IsEventTriggered("Vomit") then
						entity.StateFrame = 6
					end

				-- Lift head back to the default position
				elseif entity.StateFrame == 6 then
					if not sprite:IsPlaying("HeadSlam") then
						mod:LoopingAnim(sprite, "HeadIdle")
					end

					if entity.PositionOffset.Y <= Settings.HeadHeight then
						entity.State = NpcState.STATE_IDLE
						entity.PositionOffset = Vector(0, Settings.HeadHeight)
						sprite.Offset = Vector.Zero

					else
						entity.PositionOffset = mod:Lerp(entity.PositionOffset, Vector(0, Settings.HeadHeight - 10), 0.1)
						sprite.Offset = mod:Lerp(sprite.Offset, Vector.Zero, 0.15)
					end
				end


			-- Spit out an egg sack
			elseif entity.State == NpcState.STATE_SUMMON then
				if sprite:IsEventTriggered("Vomit") then
					local params = ProjectileParams()
					params.Variant = IRFentities.EggSackProjectile
					params.FallingAccelModifier = 1.5
					params.FallingSpeedModifier = -15
					params.HeightModifier = Settings.HeadHeight + 40
					params.BulletFlags = (ProjectileFlags.DECELERATE | ProjectileFlags.BOUNCE | ProjectileFlags.BOUNCE_FLOOR)
					params.Acceleration = 1.015
					mod:FireProjectiles(entity, entity.Position, (target.Position - entity.Position):Resized(11), 0, params).DepthOffset = entity.DepthOffset + 10

					-- Effects
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 5, entity.Position, Vector.Zero, entity):ToEffect()
					effect:FollowParent(entity)
					effect.DepthOffset = entity.DepthOffset + 10

					local effectSprite = effect:GetSprite()
					effectSprite.Offset = Vector(0, 10)
					effectSprite.Color = Color(0,0,0, 0.4, 1,1,1)
					effectSprite.Scale = Vector(0.5, 0.5)

					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF, 0.8)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end


			-- Force Delirium out of this form because for some reason he just deletes the data that holds the references to the legs
			elseif data.wasDelirium then
				entity.State = NpcState.STATE_ATTACK
				sprite:Play("HeadVomitStart")
				sprite:SetFrame(99)
				entity.PositionOffset = Vector(0, Settings.HeadHeight)
			end

			-- Death sound
			if entity:HasMortalDamage() then
				mod:PlaySound(entity, IRFsounds.TriachnidHurt, 1.2)
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

				-- Remove collision
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

				-- Delirious skin
				if entity.Parent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) == false then
					entity:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)

					for i, segment in pairs(entity.Parent:GetData().legs[data.index]) do
						local segmentSprite = segment:GetSprite()
						segmentSprite:ReplaceSpritesheet(0, "gfx/bosses/afterbirthplus/deliriumforms/classic/boss_067_triachnid.png")
						segmentSprite:LoadGraphics()
					end
				end


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

							if not entity.Parent:GetData().init and entity.Parent:ToNPC().StateFrame ~= 2 then
								entity.Parent:ToNPC().StateFrame = 2
							end
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
						local length = math.min(300, (target.Position):Distance(entity.Parent.Position))
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

							entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
							entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

							-- Projectiles + creep
							local params = ProjectileParams()
							params.Color = IRFcolors.WhiteShot
							entity:FireProjectiles(entity.Position, Vector(10, 8), 8, params)
							mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position, 2)

							-- Effects
							local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity)
							effect.DepthOffset = entity.DepthOffset + 10
							effect:GetSprite().Color = IRFcolors.WhiteShot

							mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS)
							mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND)
							Game():ShakeScreen(6)

							-- Destroy rocks he slams
							room:DestroyGrid(room:GetGridIndex(entity.Position), true)

							-- Damage enemies he slams
							for i, enemy in pairs(Isaac.FindInRadius(entity.Position, entity.Size * entity.Scale + 15, EntityPartition.ENEMY)) do
								if enemy.Type ~= entity.Type and enemy.EntityCollisionClass >= 3 and enemy.Visible == true and enemy:IsActiveEnemy() == true then
									enemy:TakeDamage(Settings.StompDamage, DamageFlag.DAMAGE_CRUSH, EntityRef(entity.Parent), 0)
								end
							end

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
							entity.Parent:ToNPC().StateFrame = 2
							entity.Parent:GetSprite():Play("HeadLiftStop", true)

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
		local onePercent = damageAmount / 100
		local reduction = onePercent * Settings.LegDamageReduction

		target.Parent:TakeDamage(damageAmount - reduction, damageFlags + DamageFlag.DAMAGE_COUNTDOWN, damageSource, 1)
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

				-- Get leg pointyness
				local poinyness = i == 3 and Settings.LegPointyness - 15 or Settings.LegPointyness
				local footDistance = startpos:Distance(endpos)

				if footDistance > Settings.LegPointyness then
					local difference = footDistance - Settings.LegPointyness
					poinyness = math.max(0, poinyness - difference / 2)
				end

				-- Top leg is handled differently
				if i == 3 then
					leg.joint.Position = startpos + halfway + Vector(0, -poinyness)

				else
					-- Get direction
					local flippedness = leg.upperLeg:GetSprite().FlipX == true and -1 or 1

					leg.joint.Position = startpos + halfway + halfway:Rotated(90 * flippedness):Resized(-poinyness)
				end
			end
		end


		-- Death stuff
		if sprite:IsPlaying("Death") then
			-- Fall down to the ground
			if sprite:WasEventTriggered("StartFall") then
				if entity.PositionOffset.Y < Settings.LandHeight - 10 then
					-- Get falling speed
					if not data.deathFallSpeed then
						data.deathFallSpeed = 0
					else
						data.deathFallSpeed = data.deathFallSpeed + 1
					end

					entity.PositionOffset = Vector(entity.PositionOffset.X, entity.PositionOffset.Y + data.deathFallSpeed)

					-- Keep it on the same frame until he lands
					if sprite:IsEventTriggered("FallLoop") then
						sprite:SetFrame(sprite:GetFrame() - 1)
					end

				-- Landed
				elseif data.deathFallSpeed then
					data.deathFallSpeed = nil
					entity.PositionOffset = Vector.Zero
					sprite.Offset = Vector(0, -15)

					-- Effects
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity).DepthOffset = entity.DepthOffset + 10
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS)
					mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND)
					Game():ShakeScreen(7)
				end
			end

			-- Remove the legs
			if sprite:IsEventTriggered("Vomit") then
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