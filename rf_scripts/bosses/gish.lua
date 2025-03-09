local mod = ReworkedFoes

local Settings = {
	MoveSpeed = 5.25,
	Cooldown = 60,
	WallCooldown = 30,
	MaxClots = 3,

	-- Charge
	ChargeSpeed = 20,
	CreepTime = 90,
	ChargeCooldown = 20,

	-- Ceiling attack
	CeilingSpeed = 6.5,
	ShotDelay = 15,

	-- Jumping on/off of walls
	Gravity = 1,
	JumpStrength = 8,
	JumpSpeed = 16,
	LaunchSpeed = 32,

	-- Lobbed Clot
	LandHeight = 8,
	ClotSpeed = 10,
}



function mod:GishInit(entity)
	if entity.Variant == 1 then
		entity.ProjectileCooldown = Settings.Cooldown / 2
		entity:GetData().counter = 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.GishInit, EntityType.ENTITY_MONSTRO2)

function mod:GishUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()
		local room = Game():GetRoom()

		-- Get effect color and creep type
		data.effectColor = mod.Colors.Tar
		data.creepType   = EffectVariant.CREEP_BLACK

		-- Champion / Delirium / Delirious
		if mod:IsRFChampion(entity, "Gish") or data.wasDelirium or entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) == true then
			data.effectColor  = mod.Colors.WhiteShot
			data.creepType    = EffectVariant.CREEP_WHITE
			entity.SplatColor = mod.Colors.WhiteShot
		end


		-- Target any Sister Vis first
		if not entity.Target and not mod:IsRFChampion(entity, "Gish") and not data.wasDelirium then
			for i, sis in pairs(Isaac.FindByType(EntityType.ENTITY_SISTERS_VIS, -1, -1, false, false)) do
				if sis:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) ~= entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and not sis:GetData().wasDelirium then
					entity.Target = sis
					break
				end
			end
		end


		-- Stay properly attached to the wall
		local function keepOnWall()
			entity.Position = Vector(entity.Position.X, entity.V1.Y)
		end

		-- Get the wall position to stick to
		local function getWallPosition()
			local clampedPos = room:GetClampedPosition(entity.Position, entity.Size) -- This way it works even if he didn't collide with the wall
			local index = room:GetGridIndex(clampedPos + entity.TargetPosition:Resized(10))
			local pos = room:GetGridPosition(index)

			entity.V1 = Vector(entity.Position.X, pos.Y + entity.TargetPosition.Y * 14)
			keepOnWall()
		end



		--[[ Chasing on the ground ]]--
		if entity.State == NpcState.STATE_IDLE then
			mod:ChasePlayer(entity, Settings.MoveSpeed)

			if entity.Velocity:Length() > 0.1 then
				mod:LoopingAnim(sprite, "Walk")
				mod:FlipTowardsMovement(entity, sprite)
			else
				mod:LoopingAnim(sprite, "Idle")
			end


			-- Attack
			if entity.ProjectileCooldown <= 0 then
				-- Reset variables
				entity.ProjectileCooldown = Settings.Cooldown
				entity.I1 = 0
				entity.I2 = 0
				entity.StateFrame = 0

				-- Jump onto a wall after 2 regular attacks
				if data.counter >= 2 then
					entity.State = NpcState.STATE_JUMP
					data.counter = 0


				-- Regular attacks
				else
					local attackCount = 3
					-- Only have up to 3 Clots
					if mod:IsRFChampion(entity, "Gish") or Isaac.CountEntities(nil, EntityType.ENTITY_CLOTTY, 1, -1) >= Settings.MaxClots then
						attackCount = 2
					end
					local attack = mod:Random(1, attackCount)

					-- Do the spit attack instead of the jump one for Hera
					if mod:IsRFChampion(entity, "Gish") and attack == 2 then
						attack = 3
					end


					-- Hardened charge
					if attack == 1 then
						entity.State = NpcState.STATE_ATTACK

					-- Jump up
					elseif attack == 2 then
						entity.State = NpcState.STATE_ATTACK2
						sprite:Play("JumpUp", true)

					-- Spit out a Clot
					elseif attack == 3 then
						entity.State = NpcState.STATE_SUMMON
						sprite:Play("Taunt", true)
					end

					data.counter = data.counter + 1
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		--[[ Hardened charge ]]--
		elseif entity.State == NpcState.STATE_ATTACK then
			if entity.StateFrame ~= 0 and entity.StateFrame ~= 3 then
				mod:LoopingAnim(sprite, "Run")

				-- Creep
				if entity:IsFrame(3, 0) then
					-- For Hera
					if mod:IsRFChampion(entity, "Gish") then
						local creep = mod:QuickCreep(data.creepType, entity, entity.Position, 1.5, -1)
						table.insert(data.bubblies, creep)

					-- For Gish
					else
						mod:QuickCreep(data.creepType, entity, entity.Position, 1.5, Settings.CreepTime)
					end
				end

				-- Bubbling effect for Hera's creep puddles
				if data.bubblies and entity:IsFrame(5, 0) then
					for i, bubbly in pairs(data.bubblies) do
						local offset = mod:RandomVector(math.random(25))
						local bubble = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TAR_BUBBLE, 0, bubbly.Position + offset, Vector.Zero, entity)
						bubble.DepthOffset = entity.DepthOffset + 10
						bubble:GetSprite():ReplaceSpritesheet(0, "gfx/effects/hera_bubble.png")
						bubble:GetSprite():LoadGraphics()
					end
				end
			end


			-- Cooldown between charges
			if entity.StateFrame == 0 then
				mod:ChasePlayer(entity, Settings.MoveSpeed)

				if entity.Velocity:Length() > 0.1 then
					mod:LoopingAnim(sprite, "Walk")
					mod:FlipTowardsMovement(entity, sprite)
				else
					mod:LoopingAnim(sprite, "Idle")
				end

				-- Charge again
				if entity.I2 <= 0 then
					entity.StateFrame = 1
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 0.75)

					-- For Hera
					if mod:IsRFChampion(entity, "Gish") then
						data.bubblies = {}
					end

				else
					entity.I2 = entity.I2 - 1
				end


			-- Get a clear line to the player first
			elseif entity.StateFrame == 1 then
				entity.Pathfinder:FindGridPath(target.Position, Settings.ChargeSpeed / 12, 500, false)
				mod:FlipTowardsMovement(entity, sprite)

				if room:CheckLine(entity.Position, target.Position, 1, 0, false, false) or entity.Pathfinder:HasPathToPos(target.Position) == false
				or mod:IsConfused(entity) or mod:IsFeared(entity) then
					entity.StateFrame = 2
					entity.TargetPosition = mod:GetTargetVector(entity, target)
					entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
				end


			-- Charging
			elseif entity.StateFrame == 2 then
				entity.Velocity = mod:Lerp(entity.Velocity, entity.TargetPosition:Resized(Settings.ChargeSpeed), 0.055)

				-- Slam into obstacles
				if entity:CollidesWithGrid() then
					entity.StateFrame = 3
					sprite:Play("Stagger", true)
					entity.I1 = entity.I1 + 1
					entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

					-- Destroy rocks he slams into
					for i = -1, 1 do
						local pos = entity.Position + (entity.V1:Resized(entity.Scale * entity.Size) + entity.V1:Resized(15)):Rotated(i * 45)
						room:DestroyGrid(room:GetGridIndex(pos), true)
					end

					-- Projectiles
					local params = ProjectileParams()
					params.Color = data.effectColor

					-- Hera bubbly spots
					if mod:IsRFChampion(entity, "Gish") then
						for i, bubbly in pairs(data.bubblies) do
							bubbly:SetTimeout(1)

							-- Projectiles
							for j = 1, 2 do
								params.Scale = 1.65 - (j * 0.15)
								params.FallingAccelModifier = 1.25
								params.FallingSpeedModifier = -8 + (j * -6)
								entity:FireProjectiles(bubbly.Position, mod:RandomVector(2), 0, params)
							end
						end
						data.bubblies = nil

					-- Gish scattered projectiles
					else
						params.Scale = 1.5
						entity:FireBossProjectiles(8, Vector.Zero, 2, params)
						entity:FireProjectiles(entity.Position, Vector(9, 10), 9, params)
					end

					-- Effects
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):GetSprite()
					effect.Color = data.effectColor
					effect.Offset = Vector(0, -10)
					effect.Scale = Vector(entity.Scale, entity.Scale)

					mod:QuickCreep(data.creepType, entity, entity.Position, 5)
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.75)
					Game():ShakeScreen(7)

				-- Keep track of velocity before colliding
				else
					entity.V1 = entity.Velocity
					mod:FlipTowardsMovement(entity, sprite)
				end


			-- Staggered
			elseif entity.StateFrame == 3 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					-- Charge 3 times
					if entity.I1 >= 3 then
						entity.State = NpcState.STATE_IDLE

					-- Cooldown after charge
					else
						entity.StateFrame = 0
						entity.I2 = Settings.ChargeCooldown
					end
				end
			end



		--[[ Ceiling attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK2 then
			-- Jump up
			if entity.StateFrame == 0 then
				entity.Velocity = Vector.Zero

				if sprite:IsEventTriggered("Jump") then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS)
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8)

				-- Land effects
				elseif sprite:IsEventTriggered("Land") then
					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.8)
					mod:PlaySound(nil, SoundEffect.SOUND_GOOATTACH0, 1.1)

					-- Splat
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity):ToEffect()
					effect.SortingLayer = SortingLayer.SORTING_NORMAL
					effect.DepthOffset = entity.DepthOffset + 10

					local effectSprite = effect:GetSprite()
					effectSprite.Offset = Vector(0, -160 * entity.Scale)
					effectSprite.Scale = Vector(entity.Scale, entity.Scale)

					local color = data.effectColor
					color:SetTint(0.3,0.3,0.3, 1)
					effectSprite.Color = color
				end

				if sprite:IsFinished() then
					entity.StateFrame = 1
					entity.I2 = Settings.ShotDelay
					data.bubblies = {}
				end


			-- On the ceiling
			elseif entity.StateFrame == 1 then
				mod:LoopingAnim(sprite, "CeilingIdle")

				-- Get position to stay at
				local height = room:GetTopLeftPos().Y + (160 * entity.Scale)

				-- Follow the target in big rooms
				local shape = room:GetRoomShape()
				local inBigRoom = shape ~= RoomShape.ROOMSHAPE_1x1 and shape ~= RoomShape.ROOMSHAPE_IV and shape ~= RoomShape.ROOMSHAPE_2x1
				if inBigRoom == true then
					height = math.max(target.Position.Y, height)
				end

				local pos = Vector(target.Position.X, height)

				-- Stay at the top of the screen or above the target
				if entity.Position:Distance(pos) < 20 then
					entity.Velocity = mod:StopLerp(entity.Velocity)
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (pos - entity.Position):Resized(Settings.CeilingSpeed), 0.25)
				end


				-- Only attack if he's close enough vertically to his target position or he's in a big room
				local checkPos = Vector(entity.Position.X, height)

				if inBigRoom == true or entity.Position:Distance(checkPos) < 20 then
					if entity.I2 <= 0 then
						-- Go to a free position to land on
						if entity.I1 >= 3 then
							entity.StateFrame = 3
							entity.TargetPosition = room:FindFreeTilePosition(entity.Position, entity.Size * entity.Scale)

						-- Shoot
						else
							entity.StateFrame = 2
							sprite:Play("CeilingShoot", true)
						end

					else
						entity.I2 = entity.I2 - 1
					end
				end


			-- Shoot
			elseif entity.StateFrame == 2 then
				entity.Velocity = Vector.Zero

				if sprite:IsEventTriggered("Shoot") then
					-- Get position
					entity.TargetPosition = target.Position + mod:RandomVector(mod:Random(60, 120))

					-- Limit distance
					local length = math.min(320, (target.Position):Distance(entity.Position))
					entity.TargetPosition = entity.Position + (entity.TargetPosition - entity.Position):Resized(length)
					entity.TargetPosition = room:GetClampedPosition(entity.TargetPosition, 20)

					-- Target
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TARGET, 0, entity.TargetPosition, Vector.Zero, entity):ToEffect()
					effect.Timeout = 25
					effect:GetSprite().Color = Color(0.5,0.5,0.5, 1)

					-- Projectile
					local params = ProjectileParams()
					params.HeightModifier = -180
					params.FallingAccelModifier = 1.75
					params.FallingSpeedModifier = -15
					params.Color = data.effectColor
					params.Scale = 2.5

					local speed = entity.Position:Distance(entity.TargetPosition) / 26 -- Cool magic number
					mod:FireProjectiles(entity, entity.Position, (entity.TargetPosition - entity.Position):Resized(speed), 0, params, mod.Colors.TarTrail):GetData().fallingShot = true

					mod:ShootEffect(entity, 5, Vector(0, 190 * entity.Scale * -0.65), data.effectColor, 1.5)
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF, 0.8)
				end

				if sprite:IsFinished() then
					entity.StateFrame = 1
					entity.I1 = entity.I1 + 1
					entity.I2 = Settings.ShotDelay
				end


			-- Go to a free position to land on
			elseif entity.StateFrame == 3 then
				mod:LoopingAnim(sprite, "CeilingIdle")

				-- Jump down
				if entity.Position:Distance(entity.TargetPosition) < 20 then
					entity.StateFrame = 4
					sprite:Play("JumpDown", true)
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8)

				-- Go to position
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(Settings.CeilingSpeed), 0.25)
				end


			-- Jump down
			elseif entity.StateFrame == 4 then
				entity.Velocity = Vector.Zero

				if sprite:IsEventTriggered("Land") then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

					-- Creep
					for i = 1, 4 do
						mod:QuickCreep(data.creepType, entity, entity.Position + Vector.FromAngle(i * 80):Resized(50), 2.25)
					end

					-- Bubbly spots
					for i, bubbly in pairs(data.bubblies) do
						bubbly:SetTimeout(1)

						-- Projectiles
						local params = ProjectileParams()
						params.Color = data.effectColor
						params.Scale = 2.5
						params.FallingAccelModifier = 1.25
						params.FallingSpeedModifier = -26
						mod:FireProjectiles(entity, bubbly.Position, Vector.Zero, 0, params, mod.Colors.TarTrail):GetData().kickedUp = true

						for j = 0, 3 do
							params.Scale = 1.65 - (j * 0.15)
							params.FallingAccelModifier = 1.25
							params.FallingSpeedModifier = -8 + (j * -6)
							entity:FireProjectiles(bubbly.Position, mod:RandomVector(2), 0, params)
						end
					end
					data.bubblies = nil

					-- Effects
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):GetSprite().Color = data.effectColor
					mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 1.2)
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS)
					Game():ShakeScreen(8)
					Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end


			-- Droplets
			if entity.StateFrame ~= 0 and entity.StateFrame ~= 4 and entity:IsFrame(40, 0) then
				local drop = Vector(entity.Position.X + math.random(-20, 20), entity.Position.Y)
				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_DROP, 0, drop, Vector.Zero, entity):ToEffect()
				effect.PositionOffset = Vector(0, -200 * entity.Scale)
				effect:GetSprite().Color = data.effectColor
			end

			-- Bubbling effect for creep puddles
			if data.bubblies and entity:IsFrame(3, 0) then
				for i, bubbly in pairs(data.bubblies) do
					local offset = mod:RandomVector(math.random(30))
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TAR_BUBBLE, 0, bubbly.Position + offset, Vector.Zero, entity)
				end
			end



		--[[ Spit out a Clot ]]--
		elseif entity.State == NpcState.STATE_SUMMON then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Face the target before shooting
			if not sprite:WasEventTriggered("Shoot") then
				mod:FlipTowardsTarget(entity, sprite)
			end

			if sprite:IsEventTriggered("Shoot") then
				-- Hera burst projectiles
				if mod:IsRFChampion(entity, "Gish") then
					for i = -1, 1, 2 do
						local params = ProjectileParams()
						params.Color = data.effectColor
						params.Scale = 2.5
						params.FallingAccelModifier = 1.25
						params.FallingSpeedModifier = -20 + mod:Random(-5, 5)

						local vector = (target.Position - entity.Position):Rotated(i * mod:Random(10, 30))
						mod:FireProjectiles(entity, entity.Position, vector:Resized(mod:Random(6, 8)), 0, params, Color(0,0,0, 1, 0.6,0.6,0.6)):GetData().kickedUp = true
					end

				-- Gish lobbed Clot
				else
					local clotParams = ProjectileParams()
					clotParams.Variant = mod.Entities.ClotProjectile
					clotParams.FallingAccelModifier = 1.25
					clotParams.FallingSpeedModifier = -20 + mod:Random(-5, 5)
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(7), 0, clotParams)

					-- Extra projectiles
					local params = ProjectileParams()
					params.Color = data.effectColor
					params.Scale = 1.25
					entity:FireBossProjectiles(12, target.Position, 2, params)
				end

				-- Effects
				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 5, entity.Position, Vector.Zero, entity):ToEffect()
				effect:FollowParent(entity)
				effect.DepthOffset = entity.DepthOffset + 10

				local effectSprite = effect:GetSprite()
				effectSprite.Offset = Vector(0, -20)
				effectSprite.Color = data.effectColor
				effectSprite.Scale = Vector(0.6, 0.6) * entity.Scale

				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF, 0.8)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end



		--[[ Jump onto a wall ]]--
		elseif entity.State == NpcState.STATE_JUMP then
			-- Get close enough to a wall
			if entity.StateFrame == 0 then
				-- Get nearest top and bottom wall positions
				local topNearest = Vector(entity.Position.X, room:GetTopLeftPos().Y)
				local bottomNearest = Vector(entity.Position.X, room:GetBottomRightPos().Y)

				for i = -room:GetGridHeight(), room:GetGridHeight() do
					local alignedPos   = room:FindFreePickupSpawnPosition(entity.Position, 0, false, false)
					local clampedPos   = room:GetClampedPosition(entity.Position, 40 + entity.Size * entity.Scale)
					local nonShittyPos = Vector(clampedPos.X, alignedPos.Y) -- Shitty ass pathfinder doesn't work with entity sizes higher than 20

					local pos = nonShittyPos + Vector(0, i * 40)
					local grid = room:GetGridEntityFromPos(pos)

					if grid ~= nil and grid:GetType() == GridEntityType.GRID_WALL then
						if i < 0 then
							topNearest = pos
						else
							bottomNearest = pos
						end
					end
				end

				-- Get the closer one
				if entity.Position:Distance(topNearest) < entity.Position:Distance(bottomNearest) then
					entity.TargetPosition = topNearest
				else
					entity.TargetPosition = bottomNearest
				end

				entity.V1 = entity.TargetPosition
				entity.TargetPosition = room:FindFreePickupSpawnPosition(entity.TargetPosition, 0, false, false)

				-- Close enough to it
				if entity.Position:Distance(entity.TargetPosition) <= 90 then
					entity.StateFrame = 1
					sprite:Play("JumpToWall", true)

				-- Otherwise try to pathfind to it
				else
					entity.Pathfinder:FindGridPath(entity.TargetPosition, Settings.MoveSpeed / 6, 500, false)

					if entity.Velocity:Length() > 0.1 then
						mod:LoopingAnim(sprite, "Walk")
						mod:FlipTowardsMovement(entity, sprite)
					else
						mod:LoopingAnim(sprite, "Idle")
					end
				end


			-- Start jump
			elseif entity.StateFrame == 1 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Jump") then
					entity.StateFrame = 2
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_X
					entity.V2 = Vector(0, Settings.JumpStrength)

					-- Get direction
					local bool = entity.TargetPosition.Y > room:GetCenterPos().Y
					entity.TargetPosition = Vector(0, mod:GetSign(bool))

					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS)
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8)
				end


			-- Jumping to position
			elseif entity.StateFrame == 2 then
				-- Update height
				entity.V2 = Vector(0, entity.V2.Y - Settings.Gravity)
				entity.PositionOffset = Vector(0, math.min(Settings.LandHeight, entity.PositionOffset.Y - entity.V2.Y))

				if not sprite:IsPlaying("JumpToWall") then
					mod:LoopingAnim(sprite, "JumpLoop")
				end
				mod:FlipTowardsMovement(entity, sprite)

				-- Land
				if entity.Position:Distance(entity.V1) < 20 then
					entity.Velocity = mod:StopLerp(entity.Velocity)

					if entity.PositionOffset.Y >= Settings.LandHeight then
						entity.StateFrame = 3
						sprite:Play("LandOnWall", true)
						entity.Velocity = Vector.Zero
						getWallPosition()
						entity.PositionOffset = Vector.Zero

						entity:SetSize(25, Vector(entity.Scale * 1.8, entity.Scale), 12)
						entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

						sprite.Offset = Vector(0, 16)
						sprite.FlipY = entity.V1.Y < room:GetCenterPos().Y

						-- Effects
						mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.8)
						mod:PlaySound(nil, SoundEffect.SOUND_GOOATTACH0, 1.1)
					end

				-- Move to position
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.V1 - entity.Position):Resized(entity.V1:Distance(entity.Position) / 5), 0.25)
				end


			-- Landed
			elseif entity.StateFrame == 3 then
				keepOnWall()
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
					entity.ProjectileCooldown = Settings.WallCooldown / 2
				end
			end



		--[[ Moving on the wall ]]--
		elseif entity.State == NpcState.STATE_MOVE then
			keepOnWall()

			-- Stay vertically aligned to the target
			entity.TargetPosition = Vector(target.Position.X, entity.Position.Y)

			local inFrontOfMe = (entity.TargetPosition - entity.Position):Resized(40 + entity.Size * entity.Scale)
			local atMyFeet = inFrontOfMe + Vector(0, mod:GetSign(not sprite.FlipY) * 20) -- This kinda stinks

			if entity.Position:Distance(entity.TargetPosition) < 20 -- Close enough to the player
			or room:GetGridCollisionAtPos(entity.Position + inFrontOfMe) >= 4 -- There is a wall right in front of me
			or room:GetGridCollisionAtPos(entity.Position + atMyFeet) < 4 then -- There is no wall where I'm trying to move to
				entity.Velocity = mod:StopLerp(entity.Velocity)
			else
				entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(Settings.MoveSpeed), 0.25)
			end


			if entity.Velocity:Length() >= 0.5 then
				mod:LoopingAnim(sprite, "WallWalk")
				mod:FlipTowardsMovement(entity, sprite)
			else
				mod:LoopingAnim(sprite, "WallIdle")
			end


			-- Attack
			if entity.ProjectileCooldown <= 0 then
				entity.StateFrame = 0
				entity.ProjectileCooldown = Settings.WallCooldown

				-- Jump off the wall after 3 attacks
				if entity.I1 >= 3 then
					entity.State = NpcState.STATE_STOMP
					sprite:Play("JumpFromWall", true)

				else
					entity.State = NpcState.STATE_ATTACK3
					sprite:Play("JumpAcrossStart", true)
				end

				entity.I1 = entity.I1 + 1
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		--[[ Jump to the opposite side ]]--
		elseif entity.State == NpcState.STATE_ATTACK3 then
			-- Start jump
			if entity.StateFrame == 0 then
				keepOnWall()
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.StateFrame = 1
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					entity:SetSize(30, Vector(entity.Scale, entity.Scale * 1.5), 12)
					entity.Mass = 1

					-- Get direction
					local bool = entity.Position.Y <= room:GetCenterPos().Y
					entity.TargetPosition = Vector(0, mod:GetSign(bool))
					entity.Velocity = entity.TargetPosition:Resized(Settings.JumpSpeed)

					-- Effects
					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS)
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8)

					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):GetSprite()
					effect.Color = data.effectColor
					effect.FlipY = not sprite.FlipY
					effect.Offset = Vector(5, mod:GetSign(effect.FlipY) * 10)
					effect.Scale = Vector(0.75, 0.75)
				end


			-- Jumping to position
			elseif entity.StateFrame == 1 then
				entity.Velocity = mod:Lerp(entity.Velocity, entity.TargetPosition:Resized(Settings.LaunchSpeed), 0.25)
				mod:LoopingAnim(sprite, "JumpAcrossLoop")

				-- Projectiles for Hera
				if mod:IsRFChampion(entity, "Gish") then
					if entity:IsFrame(2, 0) then
						local params = ProjectileParams()
						params.Color = data.effectColor
						params.Scale = 1.5
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.2

						params.BulletFlags = ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT
						params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
						params.ChangeTimeout = 180

						entity:FireProjectiles(entity.Position, Vector.Zero, 0, params)
					end

				-- Creep for Gish
				else
					mod:QuickCreep(data.creepType, entity, entity.Position, 1.5, Settings.CreepTime)
				end

				-- Land
				if entity:CollidesWithGrid() then
					entity.StateFrame = 2
					sprite:Play("LandOnWall", true)
					entity.Velocity = Vector.Zero
					getWallPosition()

					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_X
					entity:SetSize(25, Vector(entity.Scale * 1.8, entity.Scale), 12)
					entity.Mass = 50
					sprite.FlipY = not sprite.FlipY

					-- Projectiles
					if not mod:IsRFChampion(entity, "Gish") then
						local params = ProjectileParams()
						params.Color = data.effectColor
						params.Scale = 1.5
						entity:FireProjectiles(entity.V1, Vector(12, 12), 9, params)
					end

					-- Effects
					mod:QuickCreep(data.creepType, entity, entity.V1, 5)
					mod:PlaySound(nil, SoundEffect.SOUND_GOOATTACH0, 1.1)
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.9)
					Game():ShakeScreen(6)

					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):GetSprite()
					effect.Color = data.effectColor
					effect.FlipY = sprite.FlipY
					effect.Offset = Vector(5, mod:GetSign(effect.FlipY) * 10)
				end


			-- Landed
			elseif entity.StateFrame == 2 then
				keepOnWall()
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
				end
			end



		--[[ Jump off the wall ]]--
		elseif entity.State == NpcState.STATE_STOMP then
			-- Start jump
			if entity.StateFrame == 0 then
				keepOnWall()
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Jump") then
					entity.StateFrame = 1

					-- Get position
					entity.TargetPosition = Vector(entity.Position.X, entity.Position.Y + mod:GetSign(sprite.FlipY) * 80)
					entity.TargetPosition = room:FindFreePickupSpawnPosition(entity.TargetPosition, 0, true, false)

					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					entity.V2 = Vector(0, Settings.JumpStrength)
					entity:SetSize(35, Vector(entity.Scale, entity.Scale), 12)
					entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

					sprite.Offset = Vector.Zero
					sprite.FlipY = false

					-- Effects
					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS)
					mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8)
				end


			-- Jumping
			elseif entity.StateFrame == 1 then
				if not sprite:IsPlaying("JumpFromWall") then
					mod:LoopingAnim(sprite, "JumpLoop")
				end
				mod:FlipTowardsMovement(entity, sprite)

				-- Update height
				entity.V2 = Vector(0, entity.V2.Y - Settings.Gravity)
				entity.PositionOffset = Vector(0, math.min(Settings.LandHeight, entity.PositionOffset.Y - entity.V2.Y))

				-- Land
				if entity.Position:Distance(entity.TargetPosition) < 20 then
					entity.Velocity = mod:StopLerp(entity.Velocity)

					if entity.PositionOffset.Y >= Settings.LandHeight then
						entity.StateFrame = 2
						sprite:Play("LandOnFloor", true)
						entity.PositionOffset = Vector.Zero
					end

				-- Move to position
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(entity.TargetPosition:Distance(entity.Position) / 5), 0.25)
				end


			-- Landed
			elseif entity.StateFrame == 2 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Land") then
					entity.Velocity = Vector.Zero
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

					-- Effects
					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.8)
					mod:PlaySound(nil, SoundEffect.SOUND_GOOATTACH0, 1.1)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
					entity.StateFrame = 0
					entity.ProjectileCooldown = Settings.Cooldown
				end
			end



		-- Force Delirium out of this form because for some reason he just deletes the data that holds the references to the legs
		elseif data.wasDelirium then
			entity.StateFrame = 0
			entity.State = NpcState.STATE_ATTACK2
		end


		if entity.FrameCount > 1 then
			return true

		-- Hera
		elseif mod:IsRFChampion(entity, "Gish") and not data.wasDelirium and not data.altarScampsSpawned then
			-- Remove Clots
			for i, clot in pairs(Isaac.FindByType(EntityType.ENTITY_CLOTTY, 1, -1, false, false)) do
				clot:Remove()
			end

			-- Altar Scamps
			for i = -1, 1, 2 do
				local pos = entity.Position + Vector(i * 70, 0)
				pos = Game():GetRoom():FindFreePickupSpawnPosition(pos, 0, true, true)

				local scamp = Isaac.Spawn(EntityType.ENTITY_WHIPPER, 0, 0, pos, Vector.Zero, entity)
				scamp:GetData().altarScamp = true
				scamp:GetSprite():Load("gfx/834.000_altar scamp.anm2", true)
			end

			data.altarScampsSpawned = true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.GishUpdate, EntityType.ENTITY_MONSTRO2)

function mod:GishCollision(entity, target, bool)
	if entity.Variant == 1 then
		-- Kill Clots he charges into
		if target.Type == EntityType.ENTITY_CLOTTY and target.Variant == 1
		and (entity:ToNPC().State == NpcState.STATE_ATTACK or entity:ToNPC().State == NpcState.STATE_ATTACK3) and entity:ToNPC().StateFrame == 1 then
			target:Kill()

		elseif (target.Type == entity.Type or target.SpawnerType == entity.Type) then
			return true -- Ignore collision
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.GishCollision, EntityType.ENTITY_MONSTRO2)



--[[ Falling shots ]]--
function mod:GishFallingShots(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_MONSTRO2 and projectile.SpawnerVariant == 1 and projectile.SpawnerEntity and projectile:IsDead()
	and (projectile:GetData().fallingShot or projectile:GetData().kickedUp) then
		local spawner = projectile.SpawnerEntity:ToNPC()
		local spawnerData = spawner:GetData()

		local params = ProjectileParams()
		params.Color = spawnerData.effectColor


		-- From the ceiling
		if projectile:GetData().fallingShot then
			local creep = mod:QuickCreep(spawnerData.creepType, spawner, projectile.Position, 2.5, -1)
			table.insert(spawnerData.bubblies, creep)

			-- Projectiles
			spawner:FireProjectiles(projectile.Position, Vector(8, 4), 6, params)

			for i = 0, 4 do
				params.Scale = 1.65 - (i * 0.15)
				params.FallingAccelModifier = 1.25
				params.FallingSpeedModifier = -8 + (i * -6)
				spawner:FireProjectiles(projectile.Position, mod:RandomVector(1.5), 0, params)
			end

			mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 1.1)


		-- From Gish landing
		elseif projectile:GetData().kickedUp then
			spawner:FireProjectiles(projectile.Position, Vector(8, 4), 7, params)
			mod:PlaySound(nil, SoundEffect.SOUND_PLOP, 0.9, 1, 1)

			-- For Hera
			if mod:IsRFChampion(spawner, "Gish") then
				mod:QuickCreep(spawnerData.creepType, spawner, projectile.Position, 2, Settings.CreepTime)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.GishFallingShots, ProjectileVariant.PROJECTILE_NORMAL)



--[[ Hera's Altar Scamps champion fix (fuck this game :DDDD) ]]--
function mod:WhipperInit(entity)
	if entity:GetData().altarScamp and entity:IsChampion() then
		entity:Remove()
		local scamp = Isaac.Spawn(EntityType.ENTITY_WHIPPER, 0, 0, entity.Position, Vector.Zero, entity)
		scamp:GetData().altarScamp = true
		scamp:GetSprite():Load("gfx/834.000_altar scamp.anm2", true)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.WhipperInit, EntityType.ENTITY_WHIPPER)