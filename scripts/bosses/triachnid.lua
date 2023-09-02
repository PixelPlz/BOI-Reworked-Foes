local mod = BetterMonsters

local Settings = {
	NewHealth = 700,

	Gravity = 1,
	LandHeight = 8,

	WalkJumpStrength = 8,
}



--[[ Head and feet ]]--
function mod:triachnidInit(entity)
	if entity.Variant == 1 then
		entity.MaxHitPoints = Settings.NewHealth
		entity.HitPoints = entity.MaxHitPoints

		entity:GetSprite():Load("gfx/test/boss_dusk.anm2", true)
		entity:GetSprite():ReplaceSpritesheet(1, "")
		entity:GetSprite():LoadGraphics()

		entity.PositionOffset = Vector(0, -100)
		entity.SpriteOffset = Vector(0, 50)
		entity.DepthOffset = 110
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

		local data = entity:GetData()
		data.legs = {}
		data.counter = 0

		-- Create the legs
		for i = 1, 3 do
			-- Foot
			local foot = Isaac.Spawn(entity.Type, 10, entity.SubType, entity.Position + Vector.FromAngle(-90 + i * 120):Resized(20), Vector.Zero, entity):ToNPC()
			foot:GetData().index = i
			foot.Parent = entity
			foot:SetSize(18, Vector(entity.Scale, entity.Scale), 12)
			foot:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_NO_REWARD)
			foot:GetSprite():Load("gfx/test/boss_duskhand.anm2", true)


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
			lowerLeg.DepthOffset = 60


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
			leg.TargetPosition = room:FindFreeTilePosition(pos, 0)
			leg.V2 = Vector(0, Settings.WalkJumpStrength)
			leg.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		end


		--[[ Head ]]--
		if entity.Variant == 1 then
			entity.Velocity = Vector.Zero


			-- Idle
			if entity.State == NpcState.STATE_IDLE then
				mod:LoopingAnim(sprite, "Idle01")

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
						-- Only have up to 3 Clots
						if Isaac.CountEntities(nil, EntityType.ENTITY_CLOTTY, 1, -1) >= Settings.MaxClots then
							attackCount = 3
						end
						local attack = mod:Random(1, attackCount)
						attack = 1

						-- Vomit attack
						if attack == 1 then
							entity.State = NpcState.STATE_ATTACK
							sprite:Play("ChargeDownStart", true)
							entity.V1 = Vector(mod:Random(359), 0)

						-- Stomp attack
						elseif attack == 2 then
							entity.State = NpcState.STATE_ATTACK2
							sprite:Play("ChargeDownStart", true)

						-- Head slam attack
						elseif attack == 3 then
							entity.State = NpcState.STATE_ATTACK3
							entity.TargetPosition = entity.Position + (target.Position - entity.Position):Resized(200)
							entity.TargetPosition = Game():GetRoom():GetClampedPosition(entity.TargetPosition, 40)

						-- Spit out an egg sack
						elseif attack == 4 then
							entity.State = NpcState.STATE_SUMMON
							sprite:Play("ShootOne01", true)
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


				if entity.I1 <= 0 then
					-- Move the first leg on the list
					if data.sortedLegs[1] then
						local pos = entity.TargetPosition + Vector.FromAngle(-90 + data.sortedLegs[1]:GetData().index * 120):Resized(80)
						startLegMove(data.sortedLegs[1], pos)
						table.remove(data.sortedLegs, 1)
						entity.I1 = 30

					-- Get new direction
					else
						entity.State = NpcState.STATE_IDLE
					end

				else
					entity.I1 = entity.I1 - 1
				end


			-- Vomit attack
			elseif entity.State == NpcState.STATE_ATTACK then
				-- Start
				if entity.StateFrame == 0 then
					if sprite:IsFinished() then
						entity.StateFrame = 1
					end

				-- Loop
				elseif entity.StateFrame == 1 then
					mod:LoopingAnim(sprite, "ChargeDownLoop")

					if entity.ProjectileDelay <= 0 then
						-- Projectiles
						local params = ProjectileParams()
						params.Scale = 1 + mod:Random(10, 80) / 100
						params.Color = IRFcolors.WhiteShot

						local angle = entity.V1.X + entity.I2 * 666 -- This is dumb
						entity:FireProjectiles(entity.Position, Vector.FromAngle(angle):Resized(mod:Random(6, 11)), 0, params)
						entity:FireProjectiles(entity.Position, Vector.FromAngle(angle + 69):Resized(mod:Random(5, 9)), 0, params)

						-- Creep
						if entity.I2 % 2 == 0 then
							mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position + mod:RandomVector(mod:Random(40)), 2 + mod:Random(50) / 100)
						end

						entity.I2 = entity.I2 + 1
						entity.ProjectileDelay = 2

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I2 >= 30 then
						entity.StateFrame = 2
						sprite:Play("ChompDown", true)
					end

				-- Stop
				elseif entity.StateFrame == 2 then
					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end
				end


			-- Try to stomp on the player
			elseif entity.State == NpcState.STATE_ATTACK2 then
				if data.sortedLegs[1].State ~= NpcState.STATE_ATTACK then
					data.sortedLegs[1].State = NpcState.STATE_ATTACK
					--data.sortedLegs[1].TargetPosition = target.Position
					--data.sortedLegs[1].V2 = Vector(0, Settings.WalkJumpStrength * 4)
					data.sortedLegs[1].GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					data.sortedLegs[1].EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					data.sortedLegs[1].I1 = 30
				end


			-- Try to head smash on the player
			elseif entity.State == NpcState.STATE_ATTACK3 then
				entity.PositionOffset = mod:Lerp(entity.PositionOffset, Vector(entity.PositionOffset.X, -200), 0.15)
				-- Stay at the centroid of the feet
				local centroidX = 0
				local centroidY = 0
				for i, leg in pairs(data.legs) do
					centroidX = centroidX + leg.foot.Position.X
					centroidY = centroidY + leg.foot.Position.Y
				end

				entity.Position = Vector(centroidX, centroidY) / 3


				if entity.ProjectileCooldown <= 0 then
					entity.ProjectileCooldown = 15

					if data.sortedLegs[1] then
						data.sortedLegs[1].State = NpcState.STATE_MOVE
						local pos = entity.TargetPosition + Vector.FromAngle(-90 + data.sortedLegs[1]:GetData().index * 120):Resized(80)
						pos = Game():GetRoom():FindFreeTilePosition(pos, 0)
						data.sortedLegs[1].TargetPosition = pos
						data.sortedLegs[1].V2 = Vector(0, Settings.WalkJumpStrength)
						data.sortedLegs[1].GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
						table.remove(data.sortedLegs, 1)
					else
						entity.State = NpcState.STATE_IDLE
						entity.ProjectileCooldown = 0
					end
				
				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end


			-- Spit out an egg sack
			elseif entity.State == NpcState.STATE_SUMMON then
				if sprite:IsEventTriggered("Shoot") then
					Isaac.Spawn(EntityType.ENTITY_SINGE, 1, 0, entity.Position, (target.Position - entity.Position):Resized(6), entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end



		--[[ Feet ]]--
		elseif entity.Variant == 10 then
			-- Kill feet without a parent
			if not entity.Parent or entity.Parent:IsDead() then
				entity:Kill()


			else
				entity.MaxHitPoints = entity.Parent.MaxHitPoints
				entity.HitPoints = entity.Parent.HitPoints

				-- Idle
				if entity.State == NpcState.STATE_IDLE then
					entity.Velocity = Vector.Zero
					mod:LoopingAnim(sprite, "Idle")


				-- Moving
				elseif entity.State == NpcState.STATE_MOVE then
					-- Update height
					entity.V2 = Vector(0, entity.V2.Y - Settings.Gravity)
					entity.PositionOffset = Vector(0, math.min(Settings.LandHeight, entity.PositionOffset.Y - entity.V2.Y))

					-- Land
					if entity.Position:Distance(entity.TargetPosition) < 20 then
						entity.Velocity = mod:StopLerp(entity.Velocity)

						if entity.PositionOffset.Y >= Settings.LandHeight then
							entity.State = NpcState.STATE_IDLE
							entity.PositionOffset = Vector.Zero
							entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
							mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.45)
						end

					-- Move to position
					else
						--entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(10), 0.25)
						entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(entity.TargetPosition:Distance(entity.Position) / 8), 0.25)
					end


				-- Stomp
				elseif entity.State == NpcState.STATE_ATTACK then
					if entity.StateFrame == 0 then
						entity.TargetPosition = entity.Parent.Position + (target.Position - entity.Parent.Position):Resized(math.min(320, (target.Position):Distance(entity.Parent.Position)))

						if entity.I1 > 0 then
							entity.I1 = entity.I1 - 1
						end

						entity.PositionOffset = mod:Lerp(entity.PositionOffset, Vector(entity.PositionOffset.X, -120), 0.15)

						-- Land
						if entity.Position:Distance(entity.TargetPosition) < 20 then
							entity.Velocity = mod:StopLerp(entity.Velocity)
							if entity.I1 <= 0 then
								entity.StateFrame = 1
							end

						-- Move to position
						else
							entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(10 + entity.TargetPosition:Distance(entity.Position) / 20), 0.25)
							--entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(entity.TargetPosition:Distance(entity.Position) / 5), 0.25)
						end


					elseif entity.StateFrame == 1 then
						entity.Velocity = Vector.Zero
						if entity.PositionOffset.Y >= Settings.LandHeight then
							entity.PositionOffset = Vector.Zero
							entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
							entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
							entity.StateFrame = 2
							entity.I1 = 20

							local params = ProjectileParams()
							params.Color = IRFcolors.WhiteShot
							entity:FireProjectiles(entity.Position, Vector(10, 8), 8, params)
							mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position, 2)

							local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity)
							effect.DepthOffset = entity.DepthOffset + 10
							effect:GetSprite().Color = IRFcolors.WhiteShot
							mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.9)
							mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 0.9)
							Game():ShakeScreen(9)

							-- Destroy rocks he slams
							room:DestroyGrid(room:GetGridIndex(entity.Position), true)

						else
							entity.I1 = entity.I1 + 2
							entity.PositionOffset = Vector(entity.PositionOffset.X, entity.PositionOffset.Y + (20 + entity.I1))
							--entity.PositionOffset = mod:Lerp(entity.PositionOffset, Vector(entity.PositionOffset.X, Settings.LandHeight + 10), 0.15)
						end

					elseif entity.StateFrame == 2 then
						entity.Velocity = Vector.Zero
						if entity.I1 <= 0 then
							entity.State = NpcState.STATE_MOVE
							entity.TargetPosition = entity.Parent.Position + Vector.FromAngle(-90 + data.index * 120):Resized(80)
							entity.V2 = Vector(0, Settings.WalkJumpStrength)
							entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
							entity.Parent:ToNPC().State = 3
							entity.Parent:ToNPC().ProjectileCooldown = 60
							entity.StateFrame = 0
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

		-- Remove legs on death
		if entity:GetSprite():IsFinished("Death") then
			for i, leg in pairs(data.legs) do
				for j, segment in pairs(leg) do
					if type(segment) ~= "number" and segment:ToEffect() then
						segment:Remove()

						-- Bone gibs
						if segment.SubType == 2 then
							local boneEffect = Isaac.Spawn(EntityType.ENTITY_BONY, 0, 0, segment.Position, Vector.Zero, entity)
							boneEffect.Visible = false
							boneEffect:Kill()
						end
					end
				end
			end

			data.legs = nil


		-- Update join position
		else
			for i, leg in pairs(data.legs) do
				if leg.upperLeg and leg.foot then
					-- Get positions
					local startpos = entity.Position + entity.PositionOffset
					local endpos = leg.foot.Position + leg.foot.PositionOffset
					local halfway = (endpos - startpos) / 2

					-- Top leg is handled differently
					if i == 3 then
						leg.joint.Position = startpos + halfway + Vector(0, -120)

					else
						-- Get direction
						local flippedness = leg.upperLeg:GetSprite().FlipX == true and -1 or 1
						leg.joint.Position = startpos + halfway + halfway:Rotated(90 * flippedness):Resized(-130)
					end
				end
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
		if entity.SubType == 0 then
			mod:LoopingAnim(sprite, "SmashIdle")


		-- Leg segments
		else
			mod:LoopingAnim(sprite, "Arm0" .. tostring(3 - entity.SubType))

			local joint
			if entity.SpawnerEntity:GetData().legs[data.index] then
				joint = entity.SpawnerEntity:GetData().legs[data.index].joint.Position
			end

			if joint and ((entity.SubType == 1 and entity.Parent) or (entity.SubType == 2 and entity.Child)) then
				-- Get direction
				local flippedness = sprite.FlipX == true and -1 or 1

				-- Get where to point towards
				local endpos = entity.Parent.Position + entity.Parent.PositionOffset
				if entity.SubType == 2 then
					endpos = entity.Child.Position + entity.Child.PositionOffset
				end

				entity.Position = (joint + endpos) / 2
				sprite.Rotation = (endpos - joint):GetAngleDegrees() * flippedness
				sprite.Scale = Vector(joint:Distance(endpos) / 200, 1)
			end
		end


	else
		entity:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.triachnidLegSegmentUpdate, IRFentities.TriachnidLeg)